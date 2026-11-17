###########################################
## VPC VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "private_subnet_cidrs" {
  description = "One CIDR per AZ (a, b, c)"
  type        = list(string)
}

variable "data_azs_name" {
  description = "List of availability zone names to deploy subnets into."
  type        = list(string)
}
