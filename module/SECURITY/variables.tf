variable "tags"{
  description = "Additional tags "
  type = map(string)
  default = {}
}
variable "project_name"{
  description = "Name of project"
  type = string
}
variable "environment"{
  description = "Environment of project"
  type = string
}

variable "vpc_id" {
  type = string
  description = "VPC id"
}
variable "vpc_cidr" {
  description = "VPC CIDR used to restrict ALB outbound traffic to workload target"
  type = string

  validation {
    condition = can(cidrnetmask(var.vpc_cidr))
    error_message = "CIDR VPC must be valid IPv4 block"
  }
}
variable "public_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the public ALB listener."
  type        = set(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.public_ingress_cidrs : can(cidrnetmask(cidr))
    ])

    error_message = "Each public_ingress_cidrs value must be a valid IPv4 CIDR."
  }
}
variable "enable_http" {
  description = "Allow traffic http to ALB "
  type = bool 
  default = true
}
variable "enable_https" {
  description = "Allow traffic https to ALB "
  type = bool 
  default = true
}
variable "backend_target_ports"{
  description = "Ports the ALB can use to reach workload"
  type = set(number)
  default = ["8080"]
  validation {
    condition = alltrue([
      for port in var.backend_target_ports : port >= 1 && port <= 65535
    ])
    error_message = "Every port must be valid between from 1 to 65535"
  }
}

