# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "ha-vpc"
  }
}

# --- Subnets ---
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# --- Route Tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Security Groups ---
resource "aws_security_group" "frontend_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "frontend-sg"
  }
}

resource "aws_security_group" "backend_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = tolist([for subnet in aws_subnet.private : subnet.cidr_block])
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-sg"
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = tolist([for subnet in aws_subnet.private : subnet.cidr_block])
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# --- Front-End Load Balancer ---
resource "aws_lb" "frontend" {
  name               = "frontend-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "frontend-lb"
  }
}

resource "aws_lb_target_group" "frontend" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# --- Front-End Auto Scaling Group ---
resource "aws_launch_template" "frontend" {
  name_prefix   = "frontend-"
  image_id      = data.aws_ami.ec2_image.image_id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.frontend_sg.id]
  }

  tags = {
    Name = "frontend-instance"
  }
}

resource "aws_autoscaling_group" "frontend" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.frontend.arn]
}

# --- Back-End Load Balancer ---
resource "aws_lb" "backend" {
  name               = "backend-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_sg.id]
  subnets            = aws_subnet.private[*].id
}

resource "aws_lb_target_group" "backend" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# --- Back-End Auto Scaling Group ---
resource "aws_launch_template" "backend" {
  name_prefix   = "backend-"
  image_id      = data.aws_ami.ec2_image.image_id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.backend_sg.id]
  }

  tags = {
    Name = "backend-instance"
  }
}

resource "aws_autoscaling_group" "backend" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.backend.arn]
}

# --- Database ---
resource "aws_db_instance" "database" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "mydb"
  username               = "admin"
  password               = "Mtfh7BQDjs"
  multi_az               = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "db-subnet-group"
  }
}

