include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "cert_manager" {
  config_path = "../cert-manager"
  skip_outputs = true
}

dependency "nginx_ingress" {
  config_path = "../nginx-ingress"
  skip_outputs = true
}
