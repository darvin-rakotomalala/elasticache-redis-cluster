###########################################
## IAM VARIABLES
###########################################

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "encryption_rest_key_arn" {
  description = "ARN of the KMS key used to encrypt the cache at rest."
  type        = string
}

variable "encryption_secret_key_arn" {
  description = "ARN of the KMS key used to encrypt secrets."
  type        = string
}

variable "elasticache_endpoint_parameter_arn" {
  description = "ARN of the SSM parameter storing the ElastiCache configuration endpoint."
  type        = string
}

variable "elasticache_port_parameter_arn" {
  description = "ARN of the SSM parameter storing the ElastiCache port."
  type        = string
}

variable "auth_secret_version_arn" {
  description = "ARN of the Secrets Manager secret version holding the ElastiCache AUTH token."
  type        = string
}
