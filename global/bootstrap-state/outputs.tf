output "state_bucket_name" {
  description = "Name of s3 bucket use for Terraform  remote state "
  value       = aws_s3_bucket.terraform_state.id
}
output "state_bucket_arn" {
  description = "ARN of s3 bucket "
  value       = aws_s3_bucket.terraform_state.arn
}
output "state_kms_key_arn" {
  description = "ARN của KMS key mã hóa Terraform state."
  value       = aws_kms_key.terraform_state.arn
}

output "bootstrap_backend_hcl" {
  description = "Nội dung backend.hcl dùng để migrate state của global/backend lên S3."

  value = <<-EOT
bucket       = "${aws_s3_bucket.terraform_state.id}"
key          = "${var.state_key_prefix}/global/backend/terraform.tfstate"
region       = "${var.aws_region}"
encrypt      = true
kms_key_id   = "${aws_kms_key.terraform_state.arn}"
use_lockfile = true
EOT
}