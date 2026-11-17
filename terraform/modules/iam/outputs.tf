###########################################
## IAM OUTPUTS
###########################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = aws_iam_role.terraform_execution.arn
}

## SSM parameter read policy
output "ssm_parameter_policy_name" {
  description = "Name of the IAM policy that allows reading the ElastiCache endpoint and port from SSM Parameter Store."
  value       = aws_iam_policy.ssm_parameter_policy.name
}

output "ssm_parameter_policy_arn" {
  description = "ARN of the IAM policy that allows reading the ElastiCache endpoint and port from SSM Parameter Store."
  value       = aws_iam_policy.ssm_parameter_policy.arn
}

## Secrets Manager read policy
output "secret_manager_policy_name" {
  description = "Name of the IAM policy that allows reading the ElastiCache AUTH token from Secrets Manager."
  value       = aws_iam_policy.secret_manager_policy.name
}

output "secret_manager_policy_arn" {
  description = "ARN of the IAM policy that allows reading the ElastiCache AUTH token from Secrets Manager."
  value       = aws_iam_policy.secret_manager_policy.arn
}
