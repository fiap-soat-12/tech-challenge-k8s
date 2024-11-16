data "aws_eks_cluster" "fiap-tech-challenge-eks-cluster" {
  name = "fiap-tech-challenge-eks-cluster"
}

data "aws_eks_cluster_auth" "fiap-tech-challenge-eks-cluster" {
  name = data.aws_eks_cluster.fiap-tech-challenge-eks-cluster.name
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = "db_credentials"
}

data "aws_ssm_parameter" "rds_endpoint" {
  name = "/tech-challenge-app/rds-endpoint"
}