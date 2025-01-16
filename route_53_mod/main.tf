# --- Route 53 Hosted Zone ---
resource "aws_route53_zone" "main" {
  name = var.domain_name 
}

# --- Front-End DNS Record ---
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.id
  name    = "www.${var.domain_name}"
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
  name    = "api.${var.domain_name}"
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
  name    = "db.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.db_A_record]
}
