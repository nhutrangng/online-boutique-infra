resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true

  lifecycle {
    precondition {
      condition = (
        var.nat_gateway_mode != "single" || 
        contains(key(var.availability_zones), var.primary_nat_az_key)
      )

      error_message = "primary_nat_az_key must exist in AZ "
    }
  }

  tags = merge(
    local.common_tags,{
      Name = "${var.project_name}-${var.environment}-vpc}"
    }
  )
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.common_tags,{
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}
resource "aws_subnet" "public" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.value.name
  cidr_block = each.value.public_cidr
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    local.cluster_discovery_tag,
    {
      Name = "${var.project_name}-${var.environment}-public-subnet-${each.key}"
      Tier = "public"
      "kubernetes.io/role/elb" = "1"
    }
  )
}
resource "aws_subnet" "private_cluster" {
  for_each = var.availability_zones
  
  vpc_id = aws_vpc.vpc.id
  availability_zone = each.value.name
  cidr_block = each.value.private_cluster_cidr
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    local.cluster_discovery_tag, 
    {
      Name = "${var.project_name}-${var.environment}-private-subnet-${each.key}"
      Tier = "private" 
    }
  )
}
resource "aws_subnet" "private_workload" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.value.name
  cidr_block = each.value.private_workload_cidr
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    local.cluster_discovery_tag,
    {
      Name = "${var.project_name}-${var.environment}-private-subnet-workload-${each.key}"
      Tier = "private-workload"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}
resource "aws_eip" "nat" {
  for_each = local.nat_gateway_az_keys

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eip-nat-${each.key}"
    }
  )
}
resource "aws_nat" "nat" {
  for_each = local.nat_gateway_az_keys

  allocation_id = aws_eip.nat[each.key].id
  subnet_id = aws_subnet.public[each.key].id

  depends_on = [ 
    aws_internet_gateway.igw
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-${each.key}"
    }
  )
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-rt-public"
      Tier = "public"
    }
  )
}
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private_cluster" {
  for_each = var.availability_zones
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-rt-private-${each.key}"
      Tier = "private"
    }
  )
}
resource "aws_route" "private_default_ipv4" {
  for_each = var.availability_zones

  route_table_id = aws_route_table.private_cluster[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat.nat[local.nat_gateway_key_by_az[each.key]].id
}
resource "aws_route_table_association" "private_cluster" {
  for_each = aws_subnet.private_cluster
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_cluster[each.key].id 
}
resource "aws_route_table_association" "private_workload" {
  for_each = aws_subnet.private_workload
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_cluster[each.key].id
}
