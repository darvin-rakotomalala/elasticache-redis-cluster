############################################
# MAIN VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "private_subnet_cidrs" {
  description = "One CIDR per AZ (a, b, c)"
  type        = list(string)
}
