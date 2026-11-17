###########################################
## KMS VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "primary_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "principal_root_arn" {
  description = "The ARN of the AWS account root principal (e.g., arn:aws:iam::<account-id>:root) granted permissions in resource policies."
  type        = string
}

variable "principal_logs_arn" {
  description = "The ARN of the AWS CloudWatch Logs service principal (e.g., logs.<region>.amazonaws.com) granted permissions to write to the resource."
  type        = string
}

variable "slow_log_arn" {
  description = "The ARN of the CloudWatch Log Group used for storing slow query logs."
  type        = string
}

variable "engine_log_arn" {
  description = "The ARN of the CloudWatch Log Group used for storing database or service engine logs."
  type        = string
}
