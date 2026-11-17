###########################################
## KMS
###########################################

resource "aws_kms_key" "encryption_secret" {
  enable_key_rotation     = true
  description             = "Key to encrypt secret"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-encryption-secret"
  })
}

resource "aws_kms_alias" "encryption_secret" {
  name          = "alias/${var.naming_prefix}-encryption-secret"
  target_key_id = aws_kms_key.encryption_secret.key_id
}

resource "aws_kms_key_policy" "encryption_secret_policy" {
  key_id = aws_kms_key.encryption_secret.id
  policy = jsonencode({
    Id      = "${var.naming_prefix}-encryption-secret"
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.current_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow access through AWS Secrets Manager for all principals in the account that are authorized to use AWS Secrets Manager"
        Effect = "Allow"
        Principal = {
          AWS = ["*"]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = "${var.current_account_id}"
            "kms:ViaService"    = "secretsmanager.${var.primary_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_kms_key" "encryption_rest" {
  enable_key_rotation     = true
  description             = "Key to encrypt cache at rest."
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-encryption-rest"
  })
}

resource "aws_kms_alias" "encryption_rest" {
  name          = "alias/${var.naming_prefix}-encryption-rest"
  target_key_id = aws_kms_key.encryption_rest.key_id
}

resource "aws_kms_key_policy" "encryption_rest_policy" {
  key_id = aws_kms_key.encryption_rest.id
  policy = jsonencode({
    Id = "${var.naming_prefix}-encryption-rest"
    Statement = [
      {
        Action = ["kms:*"]
        Effect = "Allow"
        Principal = {
          AWS = "${var.principal_root_arn}"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      {
        Sid    = "Allow ElastiCache to use the key"
        Effect = "Allow"
        Principal = {
          Service = "elasticache.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Effect : "Allow",
        Principal : {
          Service : "${var.principal_logs_arn}"
        },
        Action : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource : "*",
        Condition : {
          ArnEquals : {
            "kms:EncryptionContext:aws:logs:arn" : [var.slow_log_arn, var.engine_log_arn]
          }
        }
      }
    ]
    Version = "2012-10-17"
  })
}
