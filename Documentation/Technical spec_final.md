# Technical Specification: Amazon ElastiCache for Redis with Terraform

## 1. Overview

Amazon ElastiCache is AWS's managed in-memory data store service, supporting the Redis and Memcached engines. This
specification describes how to provision a **highly available, encrypted Amazon ElastiCache for Redis replication
group** with Terraform, together with the networking, security, secrets, logging and monitoring resources it depends on.

**In scope:** VPC and private subnets, security group, KMS key, Secrets Manager secret (AUTH token), ElastiCache
replication group, CloudWatch logs and alarms, SSM parameters, IAM policies for consumers.

**Out of scope:** Memcached, public connectivity, application deployment, ALB / Auto Scaling / EC2 resources.

## 2. Architecture

| Component                         | Purpose                                                                                    |
|-----------------------------------|--------------------------------------------------------------------------------------------|
| **VPC + private subnets**         | One private subnet in each of 3 Availability Zones. No internet gateway or NAT route.      |
| **Subnet group**                  | Places the cache nodes in the private subnets.                                             |
| **Security group (`redis-sg`)**   | Allows TCP 6379 only from approved application security groups.                            |
| **KMS key**                       | Customer-managed key encrypting data at rest and the CloudWatch log groups.                |
| **Secrets Manager secret**        | Stores the generated AUTH token (encryption in transit and client authentication).         |
| **ElastiCache replication group** | Redis cluster, multi-AZ, with automatic failover.                                          |
| **CloudWatch log groups**         | Receive Redis `slow-log` and `engine-log` output.                                          |
| **CloudWatch alarms + SNS topic** | Alert on CPU, memory, connections and replication health.                                  |
| **SSM Parameter Store**           | Publishes the endpoint and port for applications.                                          |
| **IAM policies**                  | Grant consumers read access to the SSM parameters and the secret (and decrypt on the key). |

![elasticache-redis-cluster.png](../elasticache-redis-cluster.png)

## 3. Design Decisions

| Topic           | Decision                                                                        | Rationale                                                                                                                                                                                                                                                |
|-----------------|---------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Cluster mode    | **Enabled** (3 shards, 2 replicas each)                                         | The original draft said "cluster mode disabled" but its code used 3 node groups and the `cluster.on` parameter group, which is cluster mode enabled. This spec follows the code. For a single shard, set `num_node_groups = 1` and `cluster-enabled no`. |
| Availability    | Multi-AZ, automatic failover                                                    | Required for high availability.                                                                                                                                                                                                                          |
| Node type       | Current generation (e.g. `cache.t4g.small` for dev, `cache.r7g.large` for prod) | `cache.t2.*` is previous generation. Size from real memory needs.                                                                                                                                                                                        |
| Parameter group | Custom group, family `redis7`                                                   | Explicit, versioned configuration instead of AWS defaults.                                                                                                                                                                                               |
| Encryption      | At rest (KMS CMK) and in transit (TLS + AUTH)                                   | Security baseline.                                                                                                                                                                                                                                       |
| Network access  | Private only, SG-to-SG rules                                                    | Least privilege; no CIDR-based exposure.                                                                                                                                                                                                                 |
| VPC CIDR        | `10.0.0.0/16` (configurable)                                                    | The draft's `18.0.0.0/16` is public address space; use RFC 1918 ranges.                                                                                                                                                                                  |

## 4. Terraform Conventions

- Pin Terraform and provider versions (`aws`, `random`) in `versions.tf`; use a remote backend (S3 with locking) for
  state.
- Parameterize through variables (`name`, `environment`, `vpc_cidr`, `node_type`, `engine_version`,
  `allowed_security_group_ids`, `alarm_sns_topic_arn`) and tag all resources via `default_tags`.
- Define security group rules as standalone `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`
  resources, each with a description, to avoid circular dependencies.
- Expose outputs for every module or stage; mark secrets `sensitive = true`.
- Suggested layout: `versions.tf`, `variables.tf`, `network.tf`, `security.tf`, `kms.tf`, `secrets.tf`, `redis.tf`,
  `monitoring.tf`, `iam.tf`, `outputs.tf`.
- Note: Terraform state stores the AUTH token in plain text. Encrypt and restrict access to the state backend.

## 5. Implementation Steps

### Step 1: VPC

- CIDR from `var.vpc_cidr` (default `10.0.0.0/16`).
- `enable_dns_support = true` and `enable_dns_hostnames = true`.
- Outputs: VPC ID and CIDR.

### Step 2: Private subnets and subnet group

- Three private subnets, one per AZ (for example `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`). No public subnets are
  needed.
- Create an `aws_elasticache_subnet_group` containing all three.
- Subnet group: `aws_elasticache_subnet_group` spans all three subnets. Reference it from your Redis cluster or
  replication group with subnet_group_name.
- Outputs: subnet IDs and subnet group name.

### Step 3: Route tables

- One private route table with no default route (no NAT gateway, no internet gateway).
- Associate it with all three subnets.
- If applications in these subnets must reach SSM or Secrets Manager, add VPC interface endpoints rather than a NAT
  gateway.
- Outputs: route table ID.

### Step 4: Security group (`redis-sg`)

- Ingress: TCP **6379**, source = the application security group(s) in `var.allowed_security_group_ids`; description *"
  Redis from application"*.
- Egress: Redis nodes need little outbound access. Prefer no rule or a narrowly scoped one; if egress is required,
  document the destination and port.
- Do not use `0.0.0.0/0` for ingress. The original draft was contradictory here (VPC CIDR in prose, `0.0.0.0/0` in the
  rule).
- Output: security group ID.

```hcl
resource "aws_security_group" "redis" {
  name_prefix = "redis-sg-"
  description = "Controls access to the ElastiCache Redis cluster"
  vpc_id      = aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_app" {
  for_each = toset(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  description                  = "Redis from application"
}
```

### Step 5: KMS key

- Customer-managed key with `enable_key_rotation = true` and a deletion window.
- Key policy with two statements: (1) the default policy granting the account root administrative access; (2) a
  statement allowing the CloudWatch Logs service principal (`logs.<region>.amazonaws.com`) to use the key, restricted by
  an `kms:EncryptionContext:aws:logs:arn` condition to the log groups created in Step 6.
- Add an alias, for example `alias/redis-<name>`.
- Outputs: key ARN and alias.

### Step 6: CloudWatch log groups

- Two log groups, `/elasticache/<name>/slow-log` and `/elasticache/<name>/engine-log`.
- Encrypt with the KMS key from Step 5; set explicit `retention_in_days`.
- Outputs: log group names and ARNs.

### Step 7: AUTH token in Secrets Manager

- Generate the token with `random_password` (16 to 128 characters; restrict `override_special` to characters Redis
  accepts, since `@`, `"` and `/` are not allowed).
- Store it in an `aws_secretsmanager_secret` encrypted with the KMS key, and reference
  `aws_secretsmanager_secret_version.auth.secret_string` from the replication group.
- Outputs: secret ARN only (never the value).

### Step 8: Parameter group and replication group

```hcl
resource "aws_elasticache_parameter_group" "redis" {
  name        = "${var.name}-redis7"
  family      = "redis7"
  description = "Parameter group for ${var.name}"

  parameter {
    name  = "cluster-enabled"
    value = "yes"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = var.name
  description          = "ElastiCache Redis for ${var.name}"

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  num_node_groups            = 3
  replicas_per_node_group    = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.redis.arn
  transit_encryption_enabled = true
  auth_token                 = aws_secretsmanager_secret_version.auth.secret_string

  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-04:00"
  maintenance_window         = "sun:05:00-sun:06:00"
  auto_minor_version_upgrade = true

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }
}
```

Improvements over the original draft: explicit engine version, custom parameter group, backups and maintenance windows,
the KMS key referenced by ARN, and removal of `lifecycle { ignore_changes = [kms_key_id] }` and
`apply_immediately = true`, which hide drift and apply changes outside maintenance windows. Reintroduce them only with a
documented reason.

Cost note: 3 shards with 2 replicas each is **9 nodes**. Size `node_type` and topology per environment.

Outputs: replication group ID, configuration endpoint address, port.

### Step 9: SSM Parameter Store

- Create `/<env>/<name>/redis/endpoint` and `/<env>/<name>/redis/port` (type `String`) from the replication group's
  `configuration_endpoint_address` and `port`.
- Outputs: parameter names.

### Step 10: IAM policies for consumers

Create two least-privilege policies to attach to application roles:

- **Endpoint access:** `ssm:GetParameter` / `ssm:GetParameters` on the two parameter ARNs from Step 9.
- **AUTH token access:** `secretsmanager:GetSecretValue` on the secret ARN, and `kms:Decrypt` on the KMS key (scoped via
  `kms:ViaService`).
- Outputs: policy ARNs.

### Step 11: CloudWatch alarms

Create an SNS topic (or accept `var.alarm_sns_topic_arn`) and one alarm per metric per node. The draft hard-coded a
single cache cluster ID; with cluster mode enabled, node IDs follow the pattern `<name>-<shard 0001..>-<node 001..>`, so
generate them dynamically.

```hcl
locals {
  redis_node_ids = [
    for p in setproduct(range(1, 4), range(1, 4)) :
    format("%s-%04d-%03d", var.name, p[0], p[1])
  ]

  redis_alarms = {
    cpu = {
      metric    = "EngineCPUUtilization"
      threshold = 75
      desc      = "Redis engine CPU utilization is high"
    }
    memory = {
      metric    = "DatabaseMemoryUsagePercentage"
      threshold = 80
      desc      = "Redis memory utilization is high"
    }
    connections = {
      metric    = "CurrConnections"
      threshold = 1000
      desc      = "Redis connection count is high"
    }
  }

  alarm_matrix = {
    for p in setproduct(keys(local.redis_alarms), local.redis_node_ids) :
    "${p[0]}-${p[1]}" => { alarm = p[0], node = p[1] }
  }
}

resource "aws_cloudwatch_metric_alarm" "redis" {
  for_each            = local.alarm_matrix
  alarm_name          = "redis-${each.value.alarm}-${each.value.node}"
  alarm_description   = local.redis_alarms[each.value.alarm].desc
  namespace           = "AWS/ElastiCache"
  metric_name         = local.redis_alarms[each.value.alarm].metric
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = local.redis_alarms[each.value.alarm].threshold
  comparison_operator = "GreaterThanThreshold"
  alarm_actions = [local.alarm_sns_topic_arn]
  ok_actions = [local.alarm_sns_topic_arn]

  dimensions = {
    CacheClusterId = each.value.node
  }
}
```

Recommended additions: `Evictions`, `ReplicationLag` (replicas) and `SwapUsage`. Tune thresholds from observed load.

Outputs: SNS topic ARN, alarm names.

## 6. Security Summary

- No public exposure; ingress only from referenced security groups.
- Data at rest encrypted with a rotated customer-managed KMS key; data in transit encrypted with TLS.
- Authentication via AUTH token stored in Secrets Manager. Consider Redis ACL users (RBAC) and token rotation for
  production.
- Consumers receive least-privilege IAM policies only.
- Terraform state is encrypted, access-controlled and versioned.

## 7. Validation and Acceptance Criteria

1. `terraform fmt -check`, `terraform validate` and a security scan (e.g. `tflint`, `checkov`) pass.
2. `terraform plan` shows the expected resources and no unintended changes on a second run (idempotency).
3. The replication group is `available` with 3 shards, 2 replicas each, spread across 3 AZs.
4. From an allowed application host: TLS connection on 6379 succeeds with the AUTH token; connection from a non-allowed
   source fails.
5. Slow and engine logs appear in CloudWatch Logs, encrypted with the KMS key.
6. SSM parameters return the correct endpoint and port; the consumer IAM policies grant access to nothing more.
7. Alarms exist for every node and the SNS subscription is confirmed.
8. Failover test: after a primary failover, the cluster recovers and clients reconnect.
