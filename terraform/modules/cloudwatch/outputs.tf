###########################################
## CLOUDWATCH OUTPUTS
###########################################

## Slow log
output "slow_log_group_name" {
  description = "Name of the CloudWatch log group for ElastiCache slow logs."
  value       = aws_cloudwatch_log_group.slow_log.name
}

output "slow_log_group_arn" {
  description = "ARN of the CloudWatch log group for ElastiCache slow logs."
  value       = aws_cloudwatch_log_group.slow_log.arn
}

## Engine log
output "engine_log_group_name" {
  description = "Name of the CloudWatch log group for ElastiCache engine logs."
  value       = aws_cloudwatch_log_group.engine_log.name
}

output "engine_log_group_arn" {
  description = "ARN of the CloudWatch log group for ElastiCache engine logs."
  value       = aws_cloudwatch_log_group.engine_log.arn
}
