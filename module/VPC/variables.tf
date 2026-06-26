variable "cidr_block" {
  type = string
  description = "CIDR block of VPC network"
  default = "10.0.0.0/16"
  validation {
    condition = can(cidrnetmask(var.cidr_block))
    error_message = "VPC cidr block must be a valid IPv4 "
  }
}
variable "nat_gateway_mode" {
  type = string
  description = "Nat gateway mode"
  default = "single"
  validation {
    condition = contains(["single","one_per_az"], var.nat_gateway_mode)
    error_message = "NAT gateway mode must be either signle or one per az"
  }
}
variable "primary_nat_az_key" {
  type = string
  description = "Primary nat AZ key"
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
}
variable "cluster_name" {
  type = string
  description = "Name of cluster"
  default = "online-boutique-cluster"
}
variable "availability_zones" {
  description = "Availability zones"
  type = map(object({
    name = string
    public_cidr = string
    private_cluster_cidr = string
    private_workload_cidr = string
  }))
  validation {
    condition= length(var.availability_zones) >= 2 
    error_message = "At least two AZs are required"
  }
  validation {
    condition = alltrue(flatten([
      [for az in values(var.availability_zones) : can(cidrnetmask(az.public_cidr))],
      [for az in values(var.availability_zones) : can(cidrnetmask(az.private_cluster_cidr))],
      [for az in values(var.availability_zones) : can(cidrnetmask(az.private_workload_cidr))]
    ]))
    error_message = "Every subnet CIDR must be valid"
  }
}
variable "tags" {
  type = map(string)
  description = "Tags"
}