locals {
  common_tags = merge(
    var.tags,
    {
      Project = var.project_name
      Environment = var.environment
      ManagedBy = "Terraform"
      Component = "Network"
    }
  )
  cluster_discovery_tag = var.cluster_name == null ? {} : {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  nat_gateway_az_keys = var.nat_gateway_mode == "single" ? toset ([
    var.primary_nat_az_key
  ]) : toset (keys(var.availability_zones))

  nat_gateway_key_by_az = {
    for az_key in keys(var.availability_zones) : 
    az_key => var.nat_gateway_mode == "single" ? var.primary_nat_az_key : az_key
  }
}