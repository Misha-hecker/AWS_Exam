output "alb_dns_name" {
  description = "DNS-ім'я Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "app_url_via_alb" {
  description = "URL застосунку напряму через ALB (для перевірки до налаштування DNS)"
  value       = "http://${aws_lb.this.dns_name}/"
}

output "app_url_via_domain" {
  description = "Публічний URL застосунку через домен"
  value       = "http://${var.domain_name}/"
}

output "ecr_repository_url" {
  description = "URI репозиторію ECR"
  value       = data.aws_ecr_repository.todoai.repository_url
}

output "image_uri" {
  description = "Повний URI Docker-образу (репозиторій:тег)"
  value       = local.image_uri
}

output "asg_name" {
  description = "Назва Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "scaling_policy_name" {
  description = "Назва autoscaling policy (target tracking по CPU)"
  value       = aws_autoscaling_policy.cpu_target.name
}

output "hosted_zone_id" {
  description = "ID hosted zone в Route53"
  value       = aws_route53_zone.this.zone_id
}

output "nameservers" {
  description = "NS-записи — їх треба вказати в панелі pp.ua/uadns"
  value       = aws_route53_zone.this.name_servers
}
