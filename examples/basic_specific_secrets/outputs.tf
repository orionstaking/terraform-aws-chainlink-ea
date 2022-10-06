output "chainlink_ea_load_balancer" {
  description = "Internal ALB endpoint to accress EA's"
  value       = module.chainlink_ea.chainlink_ea_load_balancer
}

output "chainlink_ea_endpoints" {
  description = "External Adapter endpoints that could be accessible inside VPC CIDR block"
  value       = module.chainlink_ea.chainlink_ea_endpoints
}
