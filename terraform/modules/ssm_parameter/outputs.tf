###########################################
## SSM PARAMETER STORE OUTPUTS
###########################################

## Endpoint parameter
output "elasticache_endpoint_parameter_name" {
  description = "Name of the SSM parameter storing the ElastiCache configuration endpoint."
  value       = aws_ssm_parameter.elasticache_ep.name
}

output "elasticache_endpoint_parameter_arn" {
  description = "ARN of the SSM parameter storing the ElastiCache configuration endpoint."
  value       = aws_ssm_parameter.elasticache_ep.arn
}

## Port parameter
output "elasticache_port_parameter_name" {
  description = "Name of the SSM parameter storing the ElastiCache port."
  value       = aws_ssm_parameter.elasticache_port.name
}

output "elasticache_port_parameter_arn" {
  description = "ARN of the SSM parameter storing the ElastiCache port."
  value       = aws_ssm_parameter.elasticache_port.arn
}
