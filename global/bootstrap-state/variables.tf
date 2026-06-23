variable "aws_region" {
  description = "The location of s3 bucket"
  type        = string
  default     = "ap-southeast-1"
}
variable "project_name" {
  description = " Name of this project"
  type        = string
}
variable "state_bucket_prefix" {
  description = "Prefix của S3 state bucket. Bucket thực tế sẽ tự thêm AWS Account ID và region."
  type        = string
  default     = "online-boutique-tfstate"

  validation {
    condition = (
      length(var.state_bucket_prefix) >= 3 &&
      length(var.state_bucket_prefix) <= 30 &&
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_prefix))
    )

    error_message = "state_bucket_prefix phải dài 3-30 ký tự, chỉ gồm lowercase, số và dấu gạch ngang."
  }
}
variable "state_key_prefix" {
  description = "Prefix thư mục bên trong S3 bucket."
  type        = string
  default     = "online-boutique"
}
variable "noncurrent_version_expiration_days" {
  description = "Số ngày giữ các version state cũ trước khi xóa."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days >= 30
    error_message = "Nên giữ state version cũ ít nhất 30 ngày."
  }
}
variable "additional_tags" {
  description = "Tag bổ sung cho các resource bootstrap."
  type        = map(string)
  default     = {}
}