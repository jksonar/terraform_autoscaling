variable "domain_name" {
  description = "Domain name for DNS"
}

variable "lb_frontend_read" {
  type = string
}

variable "lb_frontend_zone" {
  type = string
}

variable "lb_backend_read" {
  type = string
}

variable "lb_backend_zone" {
  type = string
}