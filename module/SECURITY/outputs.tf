output "alb_security_group_id" {
  description = "Security group ID for internet-facing ALBs."
  value       = aws_security_group.sg_alb_public.id
}

output "alb_security_group_arn" {
  description = "Security group ARN for internet-facing ALBs."
  value       = aws_security_group.sg_alb_public.arn
}