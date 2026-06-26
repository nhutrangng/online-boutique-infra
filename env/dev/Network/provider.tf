provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      local.common_tags,
      {
        Project = var.project_name 
        Environment = var.environment
        ManagedBy = "Terraform"
      }
    )
  }
}