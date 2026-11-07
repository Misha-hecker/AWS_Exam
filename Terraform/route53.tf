# Hosted zone для публічного домену (пункт 4 завдання).
# Після apply треба вручну замінити NS-записи в панелі pp.ua/uadns —
# див. README, розділ "Делегування домену".
resource "aws_route53_zone" "this" {
  name = var.domain_name
}

# Alias A-запис: домен -> Application Load Balancer
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
