locals {
  port               = 5000
  storage_capacity   = "10Gi"
  container_registry = "docker-registry"
}

data "kubernetes_config_map" "domain" {
  metadata {
    name = "domain"
  }
}

resource "kubernetes_persistent_volume_claim" "registry" {
  metadata {
    name      = "container-registry"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.storage_capacity
      }
    }
  }
}


data "kubernetes_secret" "container_registry" {
  metadata {
    name = "container-registry"
  }
}

resource "htpasswd_password" "container_registry" {
  password = jsondecode(data.kubernetes_secret.container_registry.data[".dockerconfigjson"])[data.kubernetes_config_map.domain.data.domain].password
}

resource "kubernetes_secret" "htpasswd" {
  metadata {
    name      = "container-registry-htpasswd"
  }

  data = {
    "htpasswd" : resource.htpasswd_password.container_registry.bcrypt
  }
}

resource "kubernetes_stateful_set" "registry" {
  metadata {
    name      = "container-registry"
    labels = {
      app = "container-registry"
    }
  }

  spec {
    service_name = "container-registry"

    selector {
      match_labels = {
        app = "container-registry"
      }
    }

    template {
      metadata {
        labels = {
          app = "container-registry"
        }
      }

      spec {
        volume {
          name = "htpasswd"
          secret {
            secret_name = kubernetes_secret.htpasswd.metadata.0.name
          }
        }

        volume {
          name = "image-store"
          persistent_volume_claim {
            claim_name = "container-registry"
          }
        }

        container {
          image = "registry:2.6.2"
          name  = "container-registry"

          port {
            container_port = local.port
          }

          env {
            name  = "REGISTRY_AUTH"
            value = "htpasswd"
          }

          env {
            name  = "REGISTRY_AUTH_HTPASSWD_REALM"
            value = "basic-realm"
          }

          env {
            name  = "REGISTRY_AUTH_HTPASSWD_PATH"
            value = "/auth/htpasswd"
          }

          env {
            name  = "REGISTRY_HTTP_ADDR"
            value = ":${local.port}"
          }

          env {
            name  = "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY"
            value = "/var/lib/registry"
          }

          volume_mount {
            name       = "image-store"
            mount_path = "/var/lib/registry"
          }

          volume_mount {
            name       = "htpasswd"
            mount_path = "/auth/htpasswd"
            sub_path   = "htpasswd"
            read_only  = true
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "registry" {
  metadata {
    name      = "docker-registry"
    labels = {
      app = "docker-registry"
    }
  }
  spec {
    selector = {
      app = kubernetes_stateful_set.registry.metadata.0.labels.app
    }
    port {
      port        = local.port
      target_port = local.port
    }
  }
}

resource "kubernetes_ingress_v1" "registry" {
  metadata {
    name      = "docker-registry"
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-body-size" : "0"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" : "600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" : "600"
      "kubernetes.io/tls-acme" : "true"
      "kubernetes.io/ingress.class" : "nginx"
      "cert-manager.io/cluster-issuer" : "letsencrypt"

    }
  }
  spec {
    tls {
      hosts       = ["registry.${data.kubernetes_config_map.domain.data.domain}"]
      secret_name = "registry-tls"
    }

    rule {
      host = "registry.${data.kubernetes_config_map.domain.data.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.registry.metadata.0.name
              port {
                number = local.port
              }
            }
          }
        }
      }
    }
  }
}

provider "htpasswd" {}
