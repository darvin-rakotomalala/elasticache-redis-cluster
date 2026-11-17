# Project: Create an Amazon ElastiCache for Redis cluster using Terraform

**Amazon ElastiCache** is a fully managed, in-memory data store service provided by Amazon Web Services (AWS). It is
designed to enhance the performance and scalability of applications by providing a managed caching solution. ElastiCache
supports two popular in-memory caching engines: **Memcached** and **Redis**.

In this project, I focus only on how to provision an Amazon ElastiCache for the Redis cluster.

## Architecture Overview

***

**Core Components**

* **Networking** — VPC with 3 AZs, private subnets.
* **IAM role** — an IAM policy to access the ElastiCache cluster endpoint and port number from the Systems Manager
  Parameter Store. An IAM policy to access the ElastiCache cluster auth_token from AWS Secrets Manager secret.
* **KMS** — The AWS KMS key encrypts the cache data stored in the cache nodes.
* **AWS CloudWatch Log groups** — Amazon ElastiCache for Redis supports two types of logging via AWS CloudWatch logs:
  slow and engine logs.
* **AWS Secrets Manager** — to store the AUTH_TOKEN to encrypt the cache data in transit.
* **Amazon ElastiCache for Redis cluster** —
* **AWS Systems Manager (SSM) Parameter Store** — Store the ElastiCache endpoint and port number as parameters in the
  AWS Systems Manager Parameter Store.
* **Security groups** — `redis-sg` A security group controls access to an ElastiCache cluster’s cache nodes.

Here is the architecture diagram related to the scenario we are going to address.

![elasticache-redis-cluster.png](../elasticache-redis-cluster.png)

## Implementation steps

***

The ElastiCache for Redis cluster exists inside an Amazon VPC; subnet groups (collection of subnets), to be precise. The
service also requires a specific parameter group that holds key-value pairs of properties applicable to the ElastiCache
cluster. You can also determine the instance type of the cache nodes, the number of node groups, and replicas per node
group for the cluster. The cluster must be hosted on multiple availability zones to maintain high availability. The
cache nodes of the cluster accept connections on a specific port; hence, the attached security group requires an ingress
on that port. You can also enable logging (slow and engine logs) and publish them to AWS CloudWatch Logs for retrieval
and analysis. The ElastiCache cluster also requires an AWS KMS key to encrypt the data at rest and an AUTH token to
encrypt the data in transit.

### VPC Configuration

**Step 1 — Create an Amazon VPC and subnets to host the ElastiCache cluster**

A VPC with at least two subnets in different Availability Zones.

- CIDR: 18.0.0.0/16
- Enable DNS hostnames
- Enable DNS support (enabled by default)
- Generate the outputs

**Step 2 — Private Subnets for ElastiCache cluster - No internet access at all**

- Private subnets for ElastiCache cluster: 18.0.1.0/24 (AZ-a), 18.0.2.0/24 (AZ-b), 18.0.3.0/24 (AZ-c). The
  ElastiCache cluster does not require the public subnet at all.
- Create a subnet group to host the ElastiCache cluster. Add the private subnets to the subnet group.
- Generate the outputs

**Step 3 — Create Route Tables**

- ElastiCache cluster route table in the private subnet no NAT gateway
- Associate subnets with route tables for ElastiCache cluster
- Generate the outputs

### Security Groups

**Step 4 — Create Security Groups**

- Each Security Groups use separate security Group rules ```aws_security_group_rule``` or
  ```aws_vpc_security_group_ingress_rule``` or ```aws_vpc_security_group_egress_rule``` resources instead of inline
  rules to avoid circular dependencies. Refer the security group instead of IP addresses
- Add Descriptions to every rule
- Create a security group to access the ElastiCache cluster `redis-sg`
- A security group controls access to an ElastiCache cluster’s cache nodes. There are two blocks in a security group:
  the ingress and egress.
- Configure a Security group for ElastiCache Redis to control access to the Redis cluster `redis-sg`
    - Enable ingress on that port in the attached security group with the source set to the Amazon VPC’s CIDR. And for
      egress, set to 0.0.0.0/0.
    - port 6379
    - from cidr_blocks = "0.0.0.0/0"
    - Redis from application
- Generate the outputs

**Step 5 — Create an AWS KMS key to encrypt the cache data at rest**

- The AWS KMS key encrypts the cache data stored in the cache nodes.
- **Add an AWS KMS key policy**: The KMS key policy has two statements. The first is the default key policy, and the
  second ensures the key encrypts AWS CloudWatch Log group logs.
- Generate the outputs

**Step 6 — Configuring CloudWatch Alarms for Redis cluster**

- **Create AWS CloudWatch Log groups**: Amazon ElastiCache for Redis supports two types of logging via AWS CloudWatch
  logs: slow and engine logs.
- Enable log encryption due to the AWS KMS key policy I created in the previous step.
- Generate the outputs

Set up monitoring and alerting for your Redis cluster. Create node-level alarms for each cache cluster ID in the
replication group:

```
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "redis-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Redis CPU utilization is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    CacheClusterId = "my-redis-cluster-001"
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "redis-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis memory utilization is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    CacheClusterId = "my-redis-cluster-001"
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_connections" {
  alarm_name          = "redis-current-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "Redis connection count is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    CacheClusterId = "my-redis-cluster-001"
  }
}
```

- Generate the outputs

**Step 7: Create an AWS Secrets Manager secret to store the AUTH_TOKEN to encrypt the cache data in transit**

The `auth_token` is required to communicate with the ElastiCache cluster. I used the `random_password` resource of the
`random provider{}` to create the token.
Since this is a sensitive value, I specified an AWS Secrets Manager secret to store that and directed Terraform to fetch
the value from the Secrets Manager secret while creating the ElastiCache cluster.

- Generate the outputs

**Step 8: Create the Amazon ElastiCache for Redis cluster**

* Cluster Mode Disabled (Replication Group): For simpler use cases with a primary node and read replicas
* Generate the outputs

```
resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.elasticache_subnet.name
  replication_group_id       = var.name
  description                = "ElastiCache cluster for ${var.name}"
  node_type                  = "cache.t2.small"
  parameter_group_name       = "default.redis7.cluster.on"
  port                       = 6379
  multi_az_enabled           = true
  num_node_groups            = 3
  replicas_per_node_group    = 2
  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.encryption_rest.id
  transit_encryption_enabled = true
  auth_token                 = aws_secretsmanager_secret_version.auth.secret_string
  security_group_ids         = [aws_security_group.elasticache.id]
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
  lifecycle {
    ignore_changes = [kms_key_id]
  }
  apply_immediately = true
}
```
