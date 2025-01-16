output "lb_frontend_read" {
  value = aws_lb.frontend.name
}

output "lb_frontend_zone" {
  value = aws_lb.frontend.zone_id
}

output "lb_backend_read" {
  value = aws_lb.backend.dns_name
}

output "lb_backend_zone" {
    value = aws_lb.backend.zone_id
}

output "db_instance_endpoint_share" {
    value = aws_db_instance.database.endpoint
}