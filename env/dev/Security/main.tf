module "security_baseline" {
  source               = "../../../module/SECURITY"
  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = data.terraform_remote_state.Network.outputs.vpc_id
  vpc_cidr             = data.terraform_remote_state.Network.outputs.vpc_cidr 
  public_ingress_cidrs = var.public_ingress_cidrs
  backend_target_ports = var.backend_target_ports
  tags                 = local.common_tags
  enable_http          = "true"
  enable_https         = "true"
}