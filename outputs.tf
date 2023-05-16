output "chainlink_ea_load_balancer" {
  description = "Internal ALB endpoint to accress EA's"
  value       = aws_lb.this.dns_name
}

output "chainlink_ea_memory_db_address" {
  description = "DNS hostname of the cluster configuration endpoint"
  value       = var.cache_redis ? aws_memorydb_cluster.this[0].cluster_endpoint[0].address : ""
}

output "chainlink_ea_memory_db_port" {
  description = "Port number that the cluster configuration endpoint is listening on"
  value       = var.cache_redis ? aws_memorydb_cluster.this[0].cluster_endpoint[0].port : ""
}

output "alb_security_group_id" {
  description = "ID of security group attached to ALB. Used to configure additional rules. ALB has restricted access by default"
  value       = aws_security_group.alb_sg.id
}
