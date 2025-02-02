resource "helm_release" "kube-prometheus-stack" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring_namespaces.metadata[0].name
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "51.2.0"
  values     = [file("${path.module}/charts/kube-prometheus-stack/values.yaml")]

  timeout = 600

  depends_on = [
    kubernetes_namespace.monitoring_namespaces,
    helm_release.metrics_server
  ]
}
