variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Account region"
}

variable "vpc_name" {
  type        = string
  default     = "tech-challenge-vpc"
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

variable "alb_name" {
  type        = string
  default     = "tech-challenge-alb"
  description = "Application Load Balancer name"
}

variable "nlb_name" {
  type        = string
  default     = "tech-challenge-nlb"
  description = "Network Load Balancer name"
}
