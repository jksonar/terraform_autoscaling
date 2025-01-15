# --- Route 53 Hosted Zone ---
resource "aws_route53_zone" "main" {
  name = "example.com" # Replace with your domain name
}

# --- Front-End DNS Record ---
resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.id
  name    = "www.example.com" # Front-end domain
  type    = "A"

  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}

# --- Back-End DNS Record ---
resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.main.id
  name    = "api.example.com" # Back-end domain
  type    = "A"

  alias {
    name                   = aws_lb.backend.dns_name
    zone_id                = aws_lb.backend.zone_id
    evaluate_target_health = true
  }
}

# --- Database Record (Optional) ---
resource "aws_route53_record" "database" {
  zone_id = aws_route53_zone.main.id
  name    = "db.example.com" # Optional: Internal DNS for DB (not public)
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.database.endpoint]
}
