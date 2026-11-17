###########################################
## SECURITY GROUP OUTPUTS
###########################################

output "security_group_id" {
  description = "ID of the security group attached to the Amazon ElastiCache cluster."
  value       = aws_security_group.elasticache.id
}

output "security_group_arn" {
  description = "ARN of the security group attached to the Amazon ElastiCache cluster."
  value       = aws_security_group.elasticache.arn
}

output "security_group_name" {
  description = "Name of the security group attached to the Amazon ElastiCache cluster."
  value       = aws_security_group.elasticache.name
}

output "security_group_vpc_id" {
  description = "ID of the VPC the security group belongs to."
  value       = aws_security_group.elasticache.vpc_id
}

output "ingress_rule_id" {
  description = "ID of the ingress rule allowing Redis traffic (port 6379) from the VPC CIDR."
  value       = aws_security_group_rule.elasticache_ingress.id
}

output "egress_rule_id" {
  description = "ID of the egress rule allowing outbound traffic from the ElastiCache cluster."
  value       = aws_security_group_rule.elasticache_egress.id
}
