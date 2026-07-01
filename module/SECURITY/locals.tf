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
  backend_target_ports_as_strings = toset([
    for port in var.backend_target_ports : tostring(port)
  ])
}