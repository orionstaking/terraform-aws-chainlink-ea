output "chainlink_ea_load_balancer" {
  description = "Internal ALB endpoint to accress EA's"
  value       = aws_lb.this[0].dns_name
}

output "chainlink_ea_memory_db_address" {
  description = "DNS hostname of the cluster configuration endpoint"
  value       = aws_memorydb_cluster.this[0].cluster_endpoint[0].address
}

output "chainlink_ea_memory_db_port" {
  description = "Port number that the cluster configuration endpoint is listening on"
  value       = aws_memorydb_cluster.this[0].cluster_endpoint[0].port
}
