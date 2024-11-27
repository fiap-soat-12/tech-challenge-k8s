data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }

  filter {
    name   = "tag:Environment"
    values = ["private"]
  }
}

data "aws_subnet" "selected_subnets" {
  for_each = toset(data.aws_subnets.private_subnets.ids)
  id       = each.value
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = data.aws_eks_cluster.eks_cluster.name
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.secret_name
}

data "aws_ssm_parameter" "rds_endpoint" {
  name = "/fiap-tech-challenge/tech-challenge-rds-endpoint"
}

data "aws_instances" "eks_worker_instances" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [var.node_group_name]
  }
}

data "aws_ecr_repository" "ecr_repo" {
  name = "fiap-soat-tech-challenge-api"
}

data "aws_ecr_image" "latest_image" {
  repository_name = data.aws_ecr_repository.ecr_repo.name
  image_tag       = "latest"
}

data "aws_ip_ranges" "api_gateway" {
  services = ["API_GATEWAY"]
  regions  = [var.aws_region]
}
