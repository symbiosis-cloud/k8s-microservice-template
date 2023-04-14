include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "cert_manager" {
  config_path = "./modules/cert-manager"
  skip_outputs = true
}
