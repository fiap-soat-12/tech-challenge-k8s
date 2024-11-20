variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_name" {
  type = string
  default = "techchallenge-vpc"
  description = "Custom VPC name"
}

variable "eks_cluster_name" {
  type        = string
  default     = "fiap-tech-challenge-eks-cluster"
  description = "EKS Cluster name"
}

variable "node_group_name" {
  type        = string
  default     = "fiap-tech-challenge-node-group"
  description = "EKS Cluster name"
}

variable "secret_name" {
  type        = string
  default     = "techchallenge_db_credentials"
  description = "Secrets Manager Secret name"
}

variable "alb_name" {
  type        = string
  default     = "tech-challenge-alb"
  description = "Application Load Balancer name"
}
