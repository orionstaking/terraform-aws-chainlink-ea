output "chainlink_ea_load_balancer" {
  description = "Internal ALB endpoint to accress EA's"
  value       = aws_lb.this.dns_name
}

output "chainlink_ea_endpoints" {
  description = "External Adapter endpoints that could be accessible inside VPC CIDR block"
  value = flatten([
    for key, value in var.external_adapters : [{
      ea_name     = key
      ea_endpoint = "http://${aws_lb.this.dns_name}:${lookup(value, "alb_port", null)}"
    }]
  ])
}

output "chainlink_ea_memory_db_address" {
  description = "DNS hostname of the cluster configuration endpoint"
  value       = var.cache_redis ? aws_memorydb_cluster.this[0].cluster_endpoint[0].address : ""
}

output "chainlink_ea_memory_db_port" {
  description = "Port number that the cluster configuration endpoint is listening on"
  value       = var.cache_redis ? aws_memorydb_cluster.this[0].cluster_endpoint[0].port : ""
}
