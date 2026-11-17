###########################################
## ELASTICACHE REDIS OUTPUTS
###########################################

## Replication group
output "replication_group_id" {
  description = "ID of the ElastiCache replication group."
  value       = aws_elasticache_replication_group.app4.id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group."
  value       = aws_elasticache_replication_group.app4.arn
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint address of the Redis cluster (cluster mode enabled)."
  value       = aws_elasticache_replication_group.app4.configuration_endpoint_address
}

output "app_port" {
  description = "Port the Redis cluster listens on."
  value       = aws_elasticache_replication_group.app4.port
}

output "member_clusters" {
  description = "Identifiers of the member clusters (nodes) in the replication group."
  value       = aws_elasticache_replication_group.app4.member_clusters
}

## AUTH token secret
output "auth_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the ElastiCache AUTH token."
  value       = aws_secretsmanager_secret.elasticache_auth.arn
}

output "auth_secret_name" {
  description = "Name of the Secrets Manager secret holding the ElastiCache AUTH token."
  value       = aws_secretsmanager_secret.elasticache_auth.name
}

output "auth_secret_version_arn" {
  description = "ARN of the Secrets Manager secret holding the ElastiCache AUTH token."
  value       = aws_secretsmanager_secret_version.auth.secret_arn
}
