resource "kubernetes_config_map_v1" "grafana_configmaps" {
  metadata {
    name      = "grafana-dashboards"
    namespace = kubernetes_namespace.monitoring_namespaces.metadata[0].name
    labels = {
      "grafana_dashboard" : "1"
    }
  }

  data = {
    "default-dashboard.json" = file("${path.module}/charts/grafana/default_dashboard.json")
  }

  depends_on = [
    kubernetes_namespace.monitoring_namespaces
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = kubernetes_namespace.monitoring_namespaces.metadata[0].name
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = "8.5.1"
  values     = [file("${path.module}/charts/grafana/values.yaml")]

  timeout = 600

  depends_on = [
    kubernetes_namespace.monitoring_namespaces,
    kubernetes_config_map_v1.grafana_configmaps,
    helm_release.metrics_server
  ]
}

resource "kubernetes_ingress_v1" "grafana_ingress" {
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.monitoring_namespaces.metadata[0].name

    annotations = {
      "nginx.ingress.kubernetes.io/x-forwarded-port" = "true"
      "nginx.ingress.kubernetes.io/x-forwarded-host" = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path      = "/grafana"
          path_type = "Prefix"

          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.grafana,
  ]

}
