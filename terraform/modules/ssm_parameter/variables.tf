###########################################
## SSM PARAMETER STORE VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "encryption_rest_key_id" {
  description = "ID of the KMS key used to encrypt the cache at rest."
  type        = string
}

variable "configuration_endpoint_address" {
  description = "Configuration endpoint address of the Redis cluster (cluster mode enabled)."
  type        = string
}

variable "app_port" {
  description = "Port the Redis cluster listens on."
  type        = string
}

variable "replication_group_id" {
  description = "ID of the ElastiCache replication group."
  type        = string
}
