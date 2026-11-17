###########################################
## IAM
###########################################

# Create a policy to read from the specific parameter store
resource "aws_iam_policy" "ssm_parameter_policy" {
  name        = "${var.naming_prefix}-ssm-parameter-read-policy"
  path        = "/"
  description = "Policy to read the ElastiCache endpoint and port number stored in the SSM Parameter Store."
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource = [var.elasticache_endpoint_parameter_arn, var.elasticache_port_parameter_arn]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ]
        Resource = [var.encryption_rest_key_arn]
      }
    ]
  })
}

resource "aws_iam_policy" "secret_manager_policy" {
  name        = "${var.naming_prefix}-secret-read-policy"
  path        = "/"
  description = "Policy to read the ElastiCache AUTH Token stored in AWS Secrets Manager secret."
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [var.auth_secret_version_arn]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ]
        Resource = [var.encryption_secret_key_arn]
      }
    ]
  })
}
