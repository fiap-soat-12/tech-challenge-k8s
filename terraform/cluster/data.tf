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

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
