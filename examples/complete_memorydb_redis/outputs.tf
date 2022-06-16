output "chainlink_ea_load_balancer" {
  description = "Internal ALB endpoint to accress EA's"
  value       = module.chainlink_ea.chainlink_ea_load_balancer
}

output "chainlink_ea_endpoints" {
  description = "External Adapter endpoints that could be accessible inside VPC CIDR block"
  value       = module.chainlink_ea.chainlink_ea_endpoints
}

output "chainlink_ea_memory_db_address" {
  description = "DNS hostname of the cluster configuration endpoint"
  value       = module.chainlink_ea.chainlink_ea_memory_db_address
}

output "chainlink_ea_memory_db_port" {
  description = "Port number that the cluster configuration endpoint is listening on"
  value       = module.chainlink_ea.chainlink_ea_memory_db_port
}
