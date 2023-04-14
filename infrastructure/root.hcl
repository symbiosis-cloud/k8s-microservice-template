remote_state {
  backend = "kubernetes"
  config = {
    secret_suffix    = "${replace(path_relative_to_include(), "/", "-")}"
    load_config_file = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

retryable_errors = [
  "(?s).*failed to call webhook*",
]

retry_max_attempts = 5
retry_sleep_interval_sec = 15

inputs = {
  ingress_annotations = {
    "acme.cert-manager.io/http01-edit-in-place" : "true"
    "kubernetes.io/ingress.class" : "nginx"
    "kubernetes.io/tls-acme" : "true"
    "cert-manager.io/cluster-issuer" : "letsencrypt"
  }
}

generate "provider" {
  path = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "kubernetes" {
}

provider "helm" {
  kubernetes {
  }
}
  EOF
}
