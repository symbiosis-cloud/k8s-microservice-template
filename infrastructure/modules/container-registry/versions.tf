terraform {
  required_providers {
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "~> 1.0"
    }
  }
  required_version = ">= 0.14"
}
