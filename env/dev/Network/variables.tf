variable "owner"{
  description = "Primary Owner of this env"
  type = string
  default = "bin"

}
variable "cost_center" {
  description = "Cost allocation tag"
  type = string
  default = "learning"
}
variable "aws_region"{
  description = "REGION of project"
  type = string
  default = "ap-southeast-2"
}
variable "project_name" {
  type = string
  description = "Name of project"
  default = "online-boutique"
}
variable "environment" {
  type = string
  description = "Environment"
  default = "dev"
  validation {
    condition = var.environment == "dev"
    error_message = "This repo is for dev environment only"
  }
}
variable "availability_zones" {
  description = "Availability zones"
  type = map(object({
    name = string
    public_cidr = string
    private_cluster_cidr = string
    private_workload_cidr = string
  }))
}
variable "cluster_name" {
  description = "Planned EKS cluster name used for subnet tags."
  type        = string
  default     = "online-boutique-dev"
}