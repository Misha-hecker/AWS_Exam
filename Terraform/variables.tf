variable "aws_region" {
  description = "Регіон AWS"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Базове ім'я для ресурсів"
  type        = string
  default     = "todoai"
}

variable "ecr_repository_name" {
  description = "Назва ECR-репозиторію (створений заздалегідь через AWS CLI)"
  type        = string
  default     = "todoai"
}

variable "image_tag" {
  description = "Тег Docker-образу в ECR"
  type        = string
  default     = "v1"
}

variable "domain_name" {
  description = "Ваш публічний домен (hosted zone у Route53)"
  type        = string
  default     = "example.com"
}

variable "instance_type" {
  description = "Тип EC2-інстанса в Auto Scaling Group"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Порт застосунку (vite preview)"
  type        = number
  default     = 5173
}

variable "asg_min_size" {
  description = "Мінімальна кількість інстансів в ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Максимальна кількість інстансів в ASG"
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Бажана кількість інстансів в ASG"
  type        = number
  default     = 1
}

variable "cpu_target_value" {
  description = "Цільове середнє завантаження CPU (%) для target-tracking autoscaling policy"
  type        = number
  default     = 60
}
