#########################################################
## VPC
#########################################################

module "vpc" {
  source               = "./modules/vpc"
  common_tags          = local.common_tags
  naming_prefix        = local.naming_prefix
  data_azs_name        = data.aws_availability_zones.available.names
  private_subnet_cidrs = var.private_subnet_cidrs
  vpc_cidr             = var.vpc_cidr
}

#########################################################
## SECURITY GROUP
#########################################################

module "sg" {
  source        = "./modules/sg"
  common_tags   = local.common_tags
  naming_prefix = local.naming_prefix
  vpc_cidr      = var.vpc_cidr
  vpc_id        = module.vpc.vpc_id
}

#########################################################
## KMS
#########################################################

module "kms" {
  source             = "./modules/kms"
  common_tags        = local.common_tags
  naming_prefix      = local.naming_prefix
  current_account_id = data.aws_caller_identity.current.account_id
  engine_log_arn     = local.engine_log_arn
  primary_region     = var.primary_region
  principal_logs_arn = local.principal_logs_arn
  principal_root_arn = local.principal_root_arn
  slow_log_arn       = local.slow_log_arn
}

#########################################################
## IAM
#########################################################

module "iam" {
  source                             = "./modules/iam"
  common_tags                        = local.common_tags
  naming_prefix                      = local.naming_prefix
  auth_secret_version_arn            = module.elasticache.auth_secret_version_arn
  current_account_id                 = data.aws_caller_identity.current.account_id
  elasticache_endpoint_parameter_arn = module.ssm_parameter.elasticache_endpoint_parameter_arn
  elasticache_port_parameter_arn     = module.ssm_parameter.elasticache_port_parameter_arn
  encryption_rest_key_arn            = module.kms.encryption_rest_key_arn
  encryption_secret_key_arn          = module.kms.encryption_secret_key_arn
  github_org                         = var.github_org
  github_repo                        = var.github_repo
}

#########################################################
## ELASTICACHE
#########################################################

module "elasticache" {
  source                        = "./modules/elasticache"
  common_tags                   = local.common_tags
  naming_prefix                 = local.naming_prefix
  elasticache_subnet_group_name = module.vpc.elasticache_subnet_group_name
  encryption_rest_key_id        = module.kms.encryption_rest_key_id
  encryption_secret_key_id      = module.kms.encryption_secret_key_id
  engine_log_group_name         = module.cloudwatch.engine_log_group_name
  security_group_id             = module.sg.security_group_id
  slow_log_group_name           = module.cloudwatch.slow_log_group_name
}

#########################################################
## SSM PARAMETER STORE
#########################################################

module "ssm_parameter" {
  source                         = "./modules/ssm_parameter"
  common_tags                    = local.common_tags
  naming_prefix                  = local.naming_prefix
  app_port                       = module.elasticache.app_port
  configuration_endpoint_address = module.elasticache.configuration_endpoint_address
  encryption_rest_key_id         = module.kms.encryption_rest_key_id
  replication_group_id           = module.elasticache.replication_group_id
}

#########################################################
## CLOUDWATCH
#########################################################

module "cloudwatch" {
  source                  = "./modules/cloudwatch"
  common_tags             = local.common_tags
  naming_prefix           = local.naming_prefix
  encryption_rest_key_arn = module.kms.encryption_rest_key_arn
}
