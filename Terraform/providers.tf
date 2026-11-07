provider "aws" {
  region = var.aws_region

  # Креденціали беруться із локального файлу ~/.aws/credentials (профіль default).
  # Секрети у коді та tfvars-файлах відсутні.
}
