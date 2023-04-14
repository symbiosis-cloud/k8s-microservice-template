locals {
  ingress_annotations = {
    "kubernetes.io/ingress.class" : "nginx"
    "kubernetes.io/tls-acme" : "true"
    "cert-manager.io/cluster-issuer" : "letsencrypt"
  }
}

data "kubernetes_config_map" "domain" {
  metadata {
    name = "domain"
  }
}

data "kubernetes_config_map" "acme" {
  metadata {
    name = "acme"
  }
}

resource "kubernetes_manifest" "jaeger" {
  manifest = {
    apiVersion = "jaegertracing.io/v1"
    kind       = "Jaeger"
    metadata = {
      name      = "jaeger"
      namespace = "monitoring"
    }
    spec = {
      ingress = {
        enabled = false
      }
    }
  }
}

resource "kubernetes_ingress_v1" "jaeger" {
  metadata {
    name        = "jaeger"
    namespace   = "monitoring"
    annotations = local.ingress_annotations
  }
  spec {
    tls {
      hosts       = ["jaeger.${data.kubernetes_config_map.domain.data.domain}"]
      secret_name = "jaeger-tls"
    }

    rule {
      host = "jaeger.${data.kubernetes_config_map.domain.data.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "jaeger-query"
              port {
                number = 16686
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_default_service_account" "default" {
  metadata {
    namespace = "default"
  }
  image_pull_secret {
    name = "container-registry"
  }
}

resource "kubernetes_manifest" "cnpg_prometheus_rule" {
  manifest = yamldecode(file("./cnpg-default-alerts.yaml"))
}

resource "kubernetes_manifest" "cnpg_grafana_dashboard" {
  manifest = yamldecode(file("./cnpg-grafana-dashboard.yaml"))
}

resource "kubernetes_manifest" "nodejs_grafana_dashboard" {
  manifest = yamldecode(file("./nodejs-grafana-dashboard.yaml"))
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name      = "letsencrypt"
    }
    spec = {
      acme = {
        email = data.kubernetes_config_map.acme.data.email
        privateKeySecretRef = {
          name = "letsencrypt"
        }
        server = "https://acme-v02.api.letsencrypt.org/directory"
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }
}
