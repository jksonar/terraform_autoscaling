# --- Route 53 Hosted Zone ---
resource "aws_route53_zone" "main" {
  name = var.domain_name # Replace with your domain name
}

# --- Front-End DNS Record ---
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.id
  name    = "www.${var.domain_name}" # Front-end domain
  type    = "A"

  alias {
    name                   = var.lb_frontend_read
    zone_id                = var.lb_frontend_zone
    evaluate_target_health = true
  }
}

# --- Back-End DNS Record ---
resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.main.id
  name    = "api.${var.domain_name}" # Back-end domain
  type    = "A"

  alias {
    name                   = var.lb_backend_read
    zone_id                = var.lb_backend_zone
    evaluate_target_health = true
  }
}

# --- Database Record (Optional) ---
resource "aws_route53_record" "database" {
  zone_id = aws_route53_zone.main.id
  name    = "db.${var.domain_name}" # Optional: Internal DNS for DB (not public)
  type    = "CNAME"
  ttl     = 300
  records = [var.lb_backend_zone]
}
