resource "aws_security_group" "sg_alb_public" {
  name = "${var.environment}-${var.project_name}-alb-public"
  description = "Security group allow traffic to ALB"
  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,{
      Name = "${var.environment}-${var.project_name}-alb-public"
      Role = "public-alb"
    }
  )
}
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = var.enable_http ? var.public_ingress_cidrs : toset([])
  security_group_id = aws_security_group.sg_alb_public.id
  description = "Allow traffic from port 80"
  cidr_ipv4 = each.value
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each =  var.enable_https ? var.public_ingress_cidrs : toset([])
  security_group_id = aws_security_group.sg_alb_public.id
  description = "Allow traffic from port 443"
  cidr_ipv4 = each.value
  from_port = 443
  to_port = 443 
  ip_protocol = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "alb_to_workload_targets" {
  for_each = local.backend_target_ports_as_strings

  security_group_id = aws_security_group.sg_alb_public.id
  description =  "Allow ALB traffic and health checks to workload target"
  cidr_ipv4 = var.vpc_id
  from_port = tonumber(each.value)
  to_port = tonumber(each.value)
  ip_protocol = "tcp"
}