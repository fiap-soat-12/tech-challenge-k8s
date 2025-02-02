resource "kubernetes_namespace" "monitoring_namespaces" {
  metadata {
    name = "monitoring"
  }
}

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

resource "kubernetes_secret_v1" "sonarqube_metrics_token" {
  metadata {
    name      = "sonarqube-metrics-token"
      namespace = kubernetes_namespace.monitoring_namespaces.metadata[0].name
  }

  type = "Opaque"

  data = {
    token = "ZHVtbXk="
  }
}

resource "kubernetes_manifest" "sonarqube_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "sonarqube-metrics"
      namespace = kubernetes_namespace.monitoring_namespaces.metadata[0].name
    }
    spec = {
      selector = {
        matchLabels = {
          app = "sonarqube"
        }
      }
      endpoints = [
        {
          port      = "http"
          path      = "/sonarqube/api/monitoring/metrics"
          interval  = "30s"
          scheme    = "http"
          bearerTokenSecret = {
            name = "sonarqube-metrics-token"
            key  = "token"
          }
        }
      ]
    }
  }
}

resource "local_file" "sonarqube_values" {
  content = templatefile("${path.module}/charts/sonarqube/values.yaml.tpl", {
    rds_endpoint = local.sonarqube_rds_endpoint
    rds_username = "postgres"
    rds_password = "postgres"
  })
  filename = "${path.module}/charts/sonarqube/generated-values.yaml"

  # depends_on = [kubernetes_secret_v1.sonarqube_metrics_token]
}

resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  namespace  = "monitoring"

  values = [yamlencode(yamldecode(local_file.sonarqube_values.content))]

  depends_on = [
    local_file.sonarqube_values
  ]
}


resource "kubernetes_ingress_v1" "monitoring_ingress" {
  metadata {
    name      = "monitoring-ingress"
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
        path {
          path      = "/sonarqube"
          path_type = "Prefix"

          backend {
            service {
              name = "sonarqube-sonarqube"
              port {
                number = 9000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.grafana,
    helm_release.sonarqube
  ]

}
