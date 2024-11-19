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
