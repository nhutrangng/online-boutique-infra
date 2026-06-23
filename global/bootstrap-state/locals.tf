data "aws_caller_identity" "current" {}


locals {
  common_tags = merge({
    Project     = var.project_name
    Environment = "Global"
    Component   = "terraform-backend"
    ManagedBy   = "Terrafrorm"
    Owner       = "Bin"
    },
    var.additional_tags
  )

  state_bucket_name = "${var.state_bucket_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}