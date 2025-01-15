variable "region" {
  description = "AWS region"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
}

variable "instance_type" {
  description = "Instance type for EC2 instances"
  default     = "t2.micro"
}

variable "database_name" {
  description = "Database name"
}

variable "database_username" {
  description = "Database username"
}

variable "database_password" {
  description = "Database password"
}
