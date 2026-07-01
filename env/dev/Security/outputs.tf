output "alb_security_group_id" {
  description = "Attach this security group to the internet-facing ALB."
  value       = module.security_baseline.alb_security_group_id
}

output "alb_security_group_arn" {
  value = module.security_baseline.alb_security_group_arn
}