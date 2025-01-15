# Data Source for Availability Zones
data "aws_availability_zones" "available" {}

# find ami image
data "aws_ami" "ec2_image" {
  most_recent = true
  filter {
    # find with image id
    name = "image-id"
    values = [ "ami-064519b8c76274859" ]
  }
}