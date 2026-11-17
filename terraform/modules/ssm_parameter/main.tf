###########################################
## SSM PARAMETER STORE
###########################################

resource "aws_ssm_parameter" "elasticache_ep" {
  name   = "/elasticache/${var.naming_prefix}/${var.replication_group_id}/endpoint"
  type   = "SecureString"
  key_id = var.encryption_rest_key_id
  value  = var.configuration_endpoint_address

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cluster-ssm-endpoint"
  })
}

resource "aws_ssm_parameter" "elasticache_port" {
  name   = "/elasticache/${var.naming_prefix}/${var.replication_group_id}/port"
  type   = "SecureString"
  key_id = var.encryption_rest_key_id
  value  = var.app_port

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cluster-ssm-param-port"
  })
}
