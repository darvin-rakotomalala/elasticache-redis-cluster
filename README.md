# Create an Amazon ElastiCache for Redis cluster using Terraform

Provision a production-ready, highly available **Amazon ElastiCache for Redis** cluster with Terraform, and deploy it
through a secure **GitHub Actions** pipeline that authenticates to AWS with OIDC (no long-lived access keys).

## Overview

This project focuses on provisioning an ElastiCache for Redis cluster and the resources around it, so an application
running on Amazon EC2 in the same VPC can consume it securely.

**What you get**

| Capability        | Implementation                                                          |
|:------------------|:------------------------------------------------------------------------|
| High availability | Multi-AZ, multi-node replication group with automatic failover          |
| Encryption        | At rest (customer-managed KMS key) and in transit (TLS + auth token)    |
| Observability     | Slow log and engine log delivered to CloudWatch Logs                    |
| Secrets handling  | Auth token in Secrets Manager; endpoint and port in SSM Parameter Store |
| Least privilege   | Dedicated IAM policies and a security group scoped to the cache         |
| Delivery          | Terraform + GitHub Actions (OIDC) with Checkov security scanning        |

**Why ElastiCache instead of self-hosted Redis?**

- **Managed infrastructure** — AWS handles patching, backups, and failover.
- **High availability** — Multi-AZ deployments with automatic failover.
- **Scalability** — Scale vertically (node type) or horizontally (shards, replicas).
- **Security** — VPC isolation, encryption, and authentication options.
- **Monitoring** — Built-in CloudWatch metrics and logs.

Learn more in the [AWS documentation](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/WhatIs.html).

---

## Architecture

![Architecture diagram](elasticache-redis-cluster.png)

The cache nodes run in private subnets spread across three Availability Zones inside a single VPC. Changes flow
through the pipeline: **commit & push → GitHub → GitHub Actions → AWS**.

### Components

| Component                       | Role                                                                                                                         |
|:--------------------------------|:-----------------------------------------------------------------------------------------------------------------------------|
| **Networking**                  | VPC (`10.0.0.0/16`) with three private subnets, one per AZ.                                                                  |
| **ElastiCache for Redis**       | Multi-AZ, multi-node replication group with encryption at rest and in transit.                                               |
| **Security group** (`redis-sg`) | Controls which clients can reach the cache nodes.                                                                            |
| **AWS KMS**                     | Customer-managed key that encrypts data at rest on the cache nodes.                                                          |
| **AWS Secrets Manager**         | Stores the Redis `auth_token` used to authenticate clients (alongside TLS for encryption in transit).                        |
| **SSM Parameter Store**         | Stores the cluster endpoint and port so applications never hardcode them.                                                    |
| **IAM policies**                | One policy to read the endpoint/port parameters, one to read the `auth_token` secret. Attach both to the application's role. |
| **CloudWatch Log groups**       | Receive the Redis **slow log** and **engine log**.                                                                           |
| **GitHub OIDC provider**        | Lets GitHub Actions assume an AWS role without stored credentials.                                                           |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) **>= 1.14**
- An AWS account with permissions to create the resources above
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured
- A VPC with at least two subnets in different Availability Zones (or let the Terraform code create one)
- A GitHub repository for the project (used by GitHub Actions)
- Git
- JDK 21+ and Maven 3.6+ (only for the example application)
- Basic familiarity with Redis concepts

---

## Getting Started

### 1. Provision the infrastructure

From the repository root:

```bash
cd elasticache-redis-cluster/terraform

terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file="terraform.tfvars" -out=tfplan
terraform apply tfplan -auto-approve
```

> **Tip:** applying a saved plan file guarantees that exactly what you reviewed is what gets deployed. Save it as a
> binary plan (`-out=tfplan`); use `terraform show -json tfplan` if you need a JSON copy.

![1-Outputs.png](Screenshot%20verification/1-Outputs.png)

### 2. (Optional) Migrate to a remote backend

1. Add or enable the backend configuration in `terraform/backend.tf`.
2. Migrate the existing state:

   ```bash
   terraform init -migrate-state
   ```

---

## CI/CD Workflows

Every change follows the same path: **commit & push → GitHub → GitHub Actions → AWS**. Workflows authenticate to AWS
through the GitHub OIDC identity provider, so no long-lived access keys are stored in GitHub.

| Workflow           | Purpose                                                                                          |
|:-------------------|:-------------------------------------------------------------------------------------------------|
| `checkov.yml`      | Scans the Terraform code with Checkov for misconfigurations on the repository and pull requests. |
| `deploy_infra.yml` | Runs the Terraform workflow that provisions the infrastructure.                                  |

---

## Verification

1. Open the AWS Management Console and go to **ElastiCache → Redis OSS caches** (or *Redis clusters*, depending on the
   console version).
2. Select the cluster created by Terraform and review its properties: engine version, node type, Multi-AZ,
   encryption settings, and endpoints.

   <br>

   ![2-Cluster details.png](Screenshot%20verification/2-Cluster%20details.png)

   <br>

3. Scroll down to the **Nodes** section and confirm that the nodes are spread across the expected Availability Zones.

   <br>

   ![3-Shards and nodes.png](Screenshot%20verification/3-Shards%20and%20nodes.png)

   <br>

4. Confirm the endpoint and port parameters exist in **Systems Manager → Parameter Store**, and the auth token in
   **Secrets Manager**.

---

## Security Best Practices

1. **Keep connection details out of the application.**
   Store the endpoint and port as encrypted parameters in SSM Parameter Store and grant the application permission to
   read and decrypt them. This avoids hardcoded values and keeps configuration out of source control.
2. **Grant least-privilege access to those parameters.**
   Create an IAM policy that allows reading only the endpoint and port parameters, and attach it to the role the
   application assumes.
3. **Protect the `auth_token`.**
   The token is sensitive: never embed it in the application. Store it in Secrets Manager and attach a separate IAM
   policy allowing the application's role to read that one secret.
4. **Encrypt everywhere.**
   Enable both at-rest (KMS) and in-transit (TLS) encryption.
5. **Prefer IAM authentication where supported** (Redis 7.0+), and rotate the auth token regularly if you use one.
6. **Use VPC endpoints for AWS API calls.**
   They provide private connectivity to the ElastiCache API. Application traffic to Redis itself already stays inside
   your VPC through the cache endpoints.
7. **Restrict network access.**
   Allow inbound traffic on the Redis port only from the application's security group, never from `0.0.0.0/0`.
8. **Scan infrastructure code continuously.**
   Checkov runs in CI to catch misconfigurations before they reach AWS.

---

## Operations

### Scaling

| Approach           | When to use it                                               |
|:-------------------|:-------------------------------------------------------------|
| Vertical scaling   | Change the node type for more memory or CPU.                 |
| Horizontal scaling | Add shards (cluster mode enabled) to spread data and writes. |
| Read replicas      | Add replicas to scale reads and improve availability.        |

### Backup and recovery

- Take **manual snapshots** before risky changes.
- **Restore from a snapshot** to recover data or clone an environment.
- Enable automatic daily backups with a retention period that matches your recovery objectives.

### Monitoring

Create CloudWatch alarms for the signals that matter most, such as memory usage, evictions, CPU, replication lag, and
connection counts, and review the slow and engine logs when investigating incidents.

---

## Cost Optimization

1. **Right-size your nodes** — start small and scale based on actual usage.
2. **Use Reserved Nodes** — commit to 1 or 3 years for significant savings on steady workloads.
3. **Optimize data structures** — for example, use hashes for objects instead of many string keys.
4. **Set appropriate TTLs** — prevent unbounded memory growth.
5. **Monitor usage patterns** — scale down during off-peak hours where possible.

---

## Cleanup

To destroy all resources created by this project:

```bash
terraform destroy -var-file="terraform.tfvars"
```

> **Warning:** this permanently deletes the cluster and its data. Take a snapshot first if you need to keep it.
> Review the destroy plan before confirming (add `-auto-approve` only in automated, non-production contexts).

---

## Summary

This project shows how to create an **ElastiCache for Redis** cluster on **AWS** with **Terraform**, using a managed
service that removes the operational burden of running Redis at scale while keeping security, monitoring, and
scalability in place.

**Key takeaways**

- Always enable encryption and use strong authentication.
- Configure Multi-AZ for high availability.
- Set up CloudWatch alarms for proactive monitoring.
- Choose instance types and scaling strategies that fit your workload.
- Schedule regular backups for disaster recovery.

For advanced configurations, see
the [ElastiCache documentation](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/WhatIs.html)
and consider engaging AWS Support for production deployments.
