###########################################
## KMS OUTPUTS
###########################################

output "encryption_secret_key_id" {
  description = "ID of the KMS key used to encrypt secrets."
  value       = aws_kms_key.encryption_secret.key_id
}

output "encryption_secret_key_arn" {
  description = "ARN of the KMS key used to encrypt secrets."
  value       = aws_kms_key.encryption_secret.arn
}

output "encryption_secret_alias_name" {
  description = "Alias name of the KMS key used to encrypt secrets."
  value       = aws_kms_alias.encryption_secret.name
}

output "encryption_secret_alias_arn" {
  description = "ARN of the alias for the KMS key used to encrypt secrets."
  value       = aws_kms_alias.encryption_secret.arn
}

## At-rest encryption key
output "encryption_rest_key_id" {
  description = "ID of the KMS key used to encrypt the cache at rest."
  value       = aws_kms_key.encryption_rest.key_id
}

output "encryption_rest_key_arn" {
  description = "ARN of the KMS key used to encrypt the cache at rest."
  value       = aws_kms_key.encryption_rest.arn
}

output "encryption_rest_alias_name" {
  description = "Alias name of the KMS key used to encrypt the cache at rest."
  value       = aws_kms_alias.encryption_rest.name
}

output "encryption_rest_alias_arn" {
  description = "ARN of the alias for the KMS key used to encrypt the cache at rest."
  value       = aws_kms_alias.encryption_rest.arn
}
