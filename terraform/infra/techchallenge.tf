resource "kubernetes_namespace" "techchallenge_namespaces" {
  metadata {
    name = "tech-challenge"
  }
}

resource "kubernetes_secret" "techchallenge_secrets" {
  metadata {
    name      = "tech-challenge-secret"
    namespace = kubernetes_namespace.techchallenge_namespaces.metadata[0].name
  }

  binary_data = {
    external-api-token = "QmVhcmVyIEFQUF9VU1ItMTQ5NDA0NTE4MjMwMTg4Ni0wOTEyMDgtZDIyZWFhNzAyMGYwYmYyZWU0ZTQxMDQ1ZGYxZDlmNjAtMTk4NjM1NzIzOQ=="
  }

  data = {
    db-url      = data.aws_ssm_parameter.rds_endpoint.value
    db-username = local.db_credentials["username"]
    db-password = local.db_credentials["password"]
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.techchallenge_namespaces]
}

resource "kubernetes_deployment" "techchallenge_deployments" {
  metadata {
    name      = "tech-challenge-app"
    namespace = kubernetes_namespace.techchallenge_namespaces.metadata[0].name
    labels = {
      app = "tech-challenge-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "tech-challenge-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "tech-challenge-app"
        }
      }

      spec {
        container {
          image             = data.aws_ecr_image.latest_image.image_uri
          name              = "tech-challenge-app"
          image_pull_policy = "Always"

          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/api/actuator/health"
              port = 8357
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/api/actuator/health"
              port = 8357
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 1
          }

          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "default"
          }

          env {
            name  = "EXTERNAL_API_HOST"
            value = "https://api.mercadopago.com"
          }

          env {
            name  = "EXTERNAL_API_CREATE_QR"
            value = "/instore/orders/qr/seller/collectors/1986357239/pos/FIAPSOAT12C/qrs"
          }

          env {
            name  = "EXTERNAL_API_GET_PAYMENT"
            value = "/v1/payments/"
          }

          env {
            name = "SPRING_DATASOURCE_URL"
            value_from {
              secret_key_ref {
                name = "tech-challenge-secret"
                key  = "db-url"
              }
            }
          }

          env {
            name = "SPRING_DATASOURCE_USERNAME"
            value_from {
              secret_key_ref {
                name = "tech-challenge-secret"
                key  = "db-username"
              }
            }
          }

          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value_from {
              secret_key_ref {
                name = "tech-challenge-secret"
                key  = "db-password"
              }
            }
          }

          env {
            name = "EXTERNAL_API_TOKEN"
            value_from {
              secret_key_ref {
                name = "tech-challenge-secret"
                key  = "external-api-token"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.techchallenge_secrets]
}

resource "kubernetes_service" "techchallenge_services" {
  metadata {
    name      = "tech-challenge-app-service"
    namespace = kubernetes_namespace.techchallenge_namespaces.metadata[0].name
  }

  spec {
    selector = {
      app = "tech-challenge-app"
    }

    port {
      port        = 8357
      target_port = 8357
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_ingress_v1" "tech_challenge_ingress" {
  metadata {
    name      = "tech-challenge-ingress"
    namespace = kubernetes_namespace.techchallenge_namespaces.metadata[0].name

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
          path      = "/api"
          path_type = "Prefix"

          backend {
            service {
              name = "tech-challenge-app-service"
              port {
                number = 8357
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.techchallenge_services]

}

resource "kubernetes_horizontal_pod_autoscaler_v2" "tech_challenge_hpa" {
  metadata {
    name      = "tech-challenge-hpa"
    namespace = kubernetes_namespace.techchallenge_namespaces.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "tech-challenge-app"
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"

      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 75
        }
      }
    }
  }

  depends_on = [kubernetes_service.techchallenge_services]

}
