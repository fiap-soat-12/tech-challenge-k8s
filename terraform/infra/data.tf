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

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }

  filter {
    name   = "tag:Environment"
    values = ["public"]
  }
}

data "aws_subnet" "selected_private_subnets" {
  for_each = toset(data.aws_subnets.private_subnets.ids)
  id       = each.value
}

data "aws_subnet" "selected_public_subnets" {
  for_each = toset(data.aws_subnets.public_subnets.ids)
  id       = each.value
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = data.aws_eks_cluster.eks_cluster.name
}

data "aws_instances" "eks_worker_instances" {
  filter {
    name   = "tag:eks:nodegroup-name"
    values = [var.node_group_name]
  }
}

data "aws_ip_ranges" "api_gateway" {
  services = ["API_GATEWAY"]
  regions  = [var.aws_region]
}
