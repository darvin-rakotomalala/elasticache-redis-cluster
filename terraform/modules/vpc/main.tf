###########################################
## VPC
###########################################

locals {
  azs       = slice(var.data_azs_name, 0, 3)
  az_suffix = ["a", "b", "c"]
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
resource "aws_vpc" "redis" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cluster-vpc"
  })
}

# ---------------------------------------------------------------------------
# Private subnets (one per AZ) - no public IPs on launch
# ---------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count = 3

  vpc_id                  = aws_vpc.redis.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-private-subnet-${local.az_suffix[count.index]}"
    Tier = "private"
  })
}

# ---------------------------------------------------------------------------
# Private route table: only the implicit local route (VPC CIDR).
# No Internet Gateway, no NAT Gateway, no 0.0.0.0/0 route.
# ---------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.redis.id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# ElastiCache subnet group - the Redis cluster will be deployed into this
# ---------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.naming_prefix}-cluster-subnet-group"
  description = "Private subnets for the ElastiCache Redis cluster"
  subnet_ids  = aws_subnet.private[*].id
}
