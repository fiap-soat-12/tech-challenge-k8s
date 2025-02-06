resource "local_file" "sonarqube_values" {
  content = templatefile("${path.module}/charts/sonarqube/values.yaml.tpl", {
    rds_endpoint = local.sonarqube_rds_endpoint
    rds_username = "postgres"
    rds_password = "postgres"
  })
  filename = "${path.module}/charts/sonarqube/generated-values.yaml"
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

resource "kubernetes_ingress_v1" "sonarqube_ingress" {
  metadata {
    name      = "sonarqube-ingress"
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
    helm_release.sonarqube
  ]

}
