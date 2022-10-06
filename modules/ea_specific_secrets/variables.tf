variable "project" {
  description = "Project name. Passed from main Chainlink EA's module"
  type        = string
}

variable "environment" {
  description = "Environment name. Passed from main Chainlink EA's module"
  type        = string
}

variable "ea_name" {
  description = "Name of external adapter. Passed from main Chainlink EA's module"
  type        = string
}

variable "secrets" {
  description = "Map of secrets that needs to be created in AWS SM for specific adapter. Passed from main Chainlink EA's module"
  type        = any
}

variable "role_name" {
  description = "Name of the default EA's execution role. Passed from main Chainlink EA's module"
  type        = string
}
