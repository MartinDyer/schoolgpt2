variable "location" {
  description = "The name of the location to provision the resources to"
  type        = string
}

# Environment Configuration
variable "environment" {
  description = "Environment name (e.g., production, staging, development). (Default: production)"
  type        = string
  default     = "production"
}

# School Configuration
variable "school_name" {
  description = "Name of the school (used for UI customization). (Default: School AI Assistant)"
  type        = string
  default     = "School-Safe-GPT"
}