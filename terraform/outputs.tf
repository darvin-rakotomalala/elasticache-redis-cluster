############################################
# MAIN OUTPUTS
############################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = module.iam.iam_role_terraform_execution_arn
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address of the Redis cluster (cluster mode enabled)."
  value       = module.elasticache.configuration_endpoint_address
}

output "app_port" {
  description = "Port the Redis cluster listens on."
  value       = module.elasticache.app_port
}
