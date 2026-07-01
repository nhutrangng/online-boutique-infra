variable "aws_region" {
  description = "REGION of project"
  type        = string
  default     = "ap-southeast-2"
}
variable "project_name" {
  type        = string
  description = "Name of project"
  default     = "online-boutique"
}
variable "environment" {
  type        = string
  description = "Environment"
  default     = "dev"
  validation {
    condition     = var.environment == "dev"
    error_message = "This repo is for dev environment only"
  }
}
variable "owner" {
  description = "Primary Owner of this env"
  type        = string
  default     = "bin"

}
variable "cost_center" {
  description = "Cost allocation tag"
  type        = string
  default     = "learning"
}
variable "public_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the public ALB listener."
  type        = set(string)
  default     = ["0.0.0.0/0"]
}
variable "backend_target_ports" {
  description = "Ports the ALB can use to reach workload"
  type        = set(number)
  default     = ["8080"]
}


