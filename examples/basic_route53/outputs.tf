output "chainlink_ea_load_balancer" {
  description = "Internal ALB endpoint to accress EA's"
  value       = module.chainlink_ea.chainlink_ea_load_balancer
}
