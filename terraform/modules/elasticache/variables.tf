###########################################
## ELASTICACHE REDIS VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "encryption_secret_key_id" {
  description = "ID of the KMS key used to encrypt secrets."
  type        = string
}

variable "encryption_rest_key_id" {
  description = "ID of the KMS key used to encrypt the cache at rest."
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group attached to the Amazon ElastiCache cluster."
  type        = string
}

variable "elasticache_subnet_group_name" {
  description = "The name of the ElastiCache subnet group used by the Redis cluster."
  type        = string
}

variable "slow_log_group_name" {
  description = "Name of the CloudWatch log group for ElastiCache slow logs."
  type        = string
}

variable "engine_log_group_name" {
  description = "Name of the CloudWatch log group for ElastiCache engine logs."
  type        = string
}
