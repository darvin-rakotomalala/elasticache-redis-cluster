###########################################
## ELASTICACHE REDIS
###########################################

resource "aws_secretsmanager_secret" "elasticache_auth" {
  name                    = "${var.naming_prefix}-auth"
  recovery_window_in_days = 0
  kms_key_id              = var.encryption_secret_key_id
  # checkov:skip=CKV2_AWS_57: Disabled Secrets Manager secrets automatic rotation
}

resource "aws_secretsmanager_secret_version" "auth" {
  secret_id     = aws_secretsmanager_secret.elasticache_auth.id
  secret_string = random_password.auth.result
}

resource "aws_elasticache_replication_group" "app4" {
  automatic_failover_enabled = true
  subnet_group_name          = var.elasticache_subnet_group_name
  replication_group_id       = var.naming_prefix
  description                = "ElastiCache cluster for ${var.naming_prefix}"
  node_type                  = "cache.t3.small"
  parameter_group_name       = "default.redis7.cluster.on"
  port                       = 6379
  multi_az_enabled           = true
  num_node_groups            = 1 # adjust as you need
  replicas_per_node_group    = 1 # adjust as you need
  at_rest_encryption_enabled = true
  kms_key_id                 = var.encryption_rest_key_id
  transit_encryption_enabled = true
  auth_token                 = aws_secretsmanager_secret_version.auth.secret_string
  security_group_ids         = [var.security_group_id]

  log_delivery_configuration {
    destination      = var.slow_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = var.engine_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  lifecycle {
    ignore_changes = [kms_key_id]
  }

  apply_immediately = true

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cluster"
  })
}
