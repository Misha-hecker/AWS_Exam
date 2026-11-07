# IAM-роль інстанса для pull образу з ECR.
# Ім'я має починатися з "ecsInstanceRole" — це умова існуючої політики
# AmazonECS_FullAccess для iam:PassRole до ec2.amazonaws.com.
resource "aws_iam_role" "instance" {
  name = "ecsInstanceRole-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

# Права на читання образів із ECR приватного репозиторію
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance profile — прив'язує роль до EC2-інстанса.
# Створення вимагає права iam:CreateInstanceProfile (див. README, розділ "Перевірка прав").
resource "aws_iam_instance_profile" "instance" {
  name = "ecsInstanceRole-${var.project_name}"
  role = aws_iam_role.instance.name
}
