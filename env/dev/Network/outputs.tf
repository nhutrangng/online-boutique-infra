output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "availability_zones" {
  value = module.vpc.availability_zones
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_cluster_subnet_ids" {
  value = module.vpc.private_cluster_subnet_ids
}

output "private_workload_subnet_ids" {
  value = module.vpc.private_workload_subnet_ids
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

output "nat_gateway_ids" {
  value = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  value = module.vpc.nat_gateway_public_ips
}

output "internet_gateway_id" {
  value = module.vpc.internet_gateway_id
}