data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = ["techchallenge-vpc"]
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

  depends_on = [ data.aws_vpc.selected_vpc ]
}

data "aws_subnet" "selected_private_subnets" {
  for_each = toset(data.aws_subnets.private_subnets.ids)
  id       = each.value

  depends_on = [ data.aws_subnets.private_subnets ]
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
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
