locals {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}