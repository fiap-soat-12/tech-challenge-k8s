data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "selected" {
  filter {
    name   = "availabilityZone"
    values = ["us-east-1a", "us-east-1c"]
  }
}

data "aws_subnet" "selected_subnets" {
  for_each = toset(data.aws_subnets.selected.ids)
  id       = each.value
}

data "aws_eks_cluster" "fiap-tech-challenge-eks-cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "fiap-tech-challenge-eks-cluster" {
  name = data.aws_eks_cluster.fiap-tech-challenge-eks-cluster.name
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = "techchallenge_db_credentials"
}

data "aws_ssm_parameter" "rds_endpoint" {
  name = "/fiap-tech-challenge/tech-challenge-rds-endpoint"
}


data "aws_instances" "eks_worker_nodes" {
  filter {
    name   = "tag:kubernetes.io/cluster/${var.eks_cluster_name}"
    values = ["owned"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "worker_node_details" {
  count       = length(data.aws_instances.eks_worker_nodes.ids)
  instance_id = data.aws_instances.eks_worker_nodes.ids[count.index]
}
