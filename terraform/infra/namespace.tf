resource "kubernetes_namespace" "ingress_nginx_namespaces" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "monitoring_namespaces" {
  metadata {
    name = "monitoring"
  }
}
