###########################################
## CLOUDWATCH VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "encryption_rest_key_arn" {
  description = "ARN of the KMS key used to encrypt the cache at rest."
  type        = string
}
