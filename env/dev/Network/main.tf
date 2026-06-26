module "vpc" {
  source = "../../../module/VPC"
  project_name = var.project_name
  environment = var.environment
  cluster_name = var.cluster_name
  cidr_block = "10.20.0.0/16"
  availability_zones = var.availability_zones
  nat_gateway_mode = "single"
  primary_nat_az_key = "az1"
  tags = local.common_tags
}