# Amazon Linux 2023 (x86_64) — останній доступний образ від Amazon
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Репозиторій ECR створено заздалегідь (AWS CLI, крок 2 завдання)
data "aws_ecr_repository" "todoai" {
  name = var.ecr_repository_name
}

locals {
  image_uri  = "${data.aws_ecr_repository.todoai.repository_url}:${var.image_tag}"
  ecr_domain = split("/", data.aws_ecr_repository.todoai.repository_url)[0]

  # user_data: встановлення docker, login до ECR, pull та запуск контейнера
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    exec > >(tee /var/log/todoai-userdata.log) 2>&1
    dnf install -y docker
    systemctl enable --now docker
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.ecr_domain}
    docker pull ${local.image_uri}
    docker run -d --restart=always --name todoai -p ${var.app_port}:${var.app_port} ${local.image_uri}
  EOT
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.instance.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-instance"
    }
  }

  tags = {
    Name = "${var.project_name}-lt"
  }
}
