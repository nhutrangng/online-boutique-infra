output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Selected Availability Zones keyed by logical AZ name."

  value = {
    for key, value in var.availability_zones :
    key => value.name
  }
}

output "public_subnet_ids" {
  description = "Public subnet IDs in deterministic AZ-key order."

  value = [
    for az_key in sort(keys(var.availability_zones)) :
    aws_subnet.public[az_key].id
  ]
}

output "private_cluster_subnet_ids" {
  description = "Private cluster subnet IDs in deterministic AZ-key order."

  value = [
    for az_key in sort(keys(var.availability_zones)) :
    aws_subnet.private_cluster[az_key].id
  ]
}

output "private_workload_subnet_ids" {
  description = "Private workload subnet IDs in deterministic AZ-key order."

  value = [
    for az_key in sort(keys(var.availability_zones)) :
    aws_subnet.private_workload[az_key].id
  ]
}

output "public_subnet_ids_by_az" {
  value = {
    for key, subnet in aws_subnet.public :
    key => subnet.id
  }
}

output "private_cluster_subnet_ids_by_az" {
  value = {
    for key, subnet in aws_subnet.private_cluster :
    key => subnet.id
  }
}

output "private_workload_subnet_ids_by_az" {
  value = {
    for key, subnet in aws_subnet.private_workload :
    key => subnet.id
  }
}

output "public_route_table_id" {
  description = "Shared public route table ID."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs keyed by AZ."

  value = {
    for key, route_table in aws_route_table.private :
    key => route_table.id
  }
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs keyed by the AZ where each NAT is deployed."

  value = {
    for key, nat_gateway in aws_nat_gateway.this :
    key => nat_gateway.id
  }
}

output "nat_gateway_public_ips" {
  description = "Public Elastic IPs assigned to NAT Gateways."

  value = {
    for key, eip in aws_eip.nat :
    key => eip.public_ip
  }
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.this.id
}