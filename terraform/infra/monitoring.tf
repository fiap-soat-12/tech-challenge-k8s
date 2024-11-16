resource "kubernetes_namespace" "monitoring_namespaces" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube-prometheus-stack" {
  name       = "kube-prometheus-stack"
  namespace  = "monitoring"
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

resource "kubernetes_config_map_v1" "grafana_configmaps" {
  metadata {
    name = "grafana-dashboards"
    namespace = "monitoring"
    labels = {
      "grafana_dashboard": "1"
    }
  }

  data = {
    "default-dashboard.json" = "${file("${path.module}/charts/grafana/default_dashboard.json")}"
  }

  depends_on = [
    kubernetes_namespace.monitoring_namespaces
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
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

resource "kubernetes_ingress_v1" "monitoring_ingress" {
  metadata {
    name      = "grafana-ingress"
    namespace = "monitoring"
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
  
  depends_on = [helm_release.grafana]

}
