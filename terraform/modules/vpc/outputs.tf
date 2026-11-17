###########################################
## VPC OUTPUTS
###########################################

output "vpc_id" {
  description = "The ID of the VPC created for the Redis infrastructure."
  value       = aws_vpc.redis.id
}

output "private_subnet_ids" {
  description = "A list of IDs for the private subnets hosting the ElastiCache cluster."
  value       = aws_subnet.private[*].id
}

output "private_subnet_azs" {
  description = "A list of Availability Zones corresponding to the private subnets."
  value       = aws_subnet.private[*].availability_zone
}

output "elasticache_subnet_group_name" {
  description = "The name of the ElastiCache subnet group used by the Redis cluster."
  value       = aws_elasticache_subnet_group.redis.name
}
