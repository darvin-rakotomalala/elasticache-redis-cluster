###########################################
## CLOUDWATCH
###########################################

resource "aws_cloudwatch_log_group" "slow_log" {
  name              = "/elasticache/${var.naming_prefix}/slow-log"
  retention_in_days = 30 # Adjust as you need
  kms_key_id        = var.encryption_rest_key_arn
  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cluster-slow-log"
  })
}

resource "aws_cloudwatch_log_group" "engine_log" {
  name              = "/elasticache/${var.naming_prefix}/engine-log"
  retention_in_days = 30 # Adjust as you need
  kms_key_id        = var.encryption_rest_key_arn
  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cluster-engine-log"
  })
}
