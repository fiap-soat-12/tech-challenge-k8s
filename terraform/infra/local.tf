locals {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  sonarqube_rds_endpoint = data.aws_ssm_parameter.sonarqube_rds_endpoint.value
}