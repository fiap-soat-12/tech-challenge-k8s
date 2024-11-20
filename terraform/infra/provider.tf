provider "aws" {
  region = var.aws_region
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.fiap-tech-challenge-eks-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.fiap-tech-challenge-eks-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.fiap-tech-challenge-eks-cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.fiap-tech-challenge-eks-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.fiap-tech-challenge-eks-cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.fiap-tech-challenge-eks-cluster.token
  }
}
