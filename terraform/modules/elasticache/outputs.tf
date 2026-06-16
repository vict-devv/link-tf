output "security_group_id" {
  description = "ElastiCache security group ID"
  value       = aws_security_group.redis.id
}

output "secret_arn" {
  description = "Secrets Manager ARN for Redis connection"
  value       = aws_secretsmanager_secret.redis.arn
}

output "endpoint" {
  description = "Redis endpoint (host:port)"
  value       = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
}
