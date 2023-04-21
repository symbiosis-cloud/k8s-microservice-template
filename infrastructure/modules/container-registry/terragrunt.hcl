include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "nginx_ingress" {
  config_path = "../nginx-ingress"
  skip_outputs = true
}
