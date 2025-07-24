variable "resource_group_name" {
  description = "Name for the Azure Resource Group. (Required)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources (e.g., eastus, uksouth). (Default: uksouth)"
  type        = string
  default     = "uksouth"
}

variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique, 5-50 lowercase letters/numbers). (Required)"
  type        = string
}

variable "app_service_plan_name" {
  description = "Name for the App Service Plan. (Default: schoolgpt-asp)"
  type        = string
  default     = "schoolgpt-asp"
}

variable "web_app_name" {
  description = "Name for the Azure Web App (must be globally unique). (Required)"
  type        = string
}

variable "acr_login_server" {
  description = "Login server for the Azure Container Registry (e.g., myacr.azurecr.io). (Auto-derived, can be left blank)"
  type        = string
  default     = ""
}

variable "docker_image" {
  description = "Docker image name (without registry, e.g., schoolgpt-app). (Default: schoolgpt-app)"
  type        = string
  default     = "schoolgpt-app"
}

variable "docker_tag" {
  description = "Docker image tag (e.g., latest). (Default: latest)"
  type        = string
  default     = "latest"
}

variable "promptflow_name" {
  description = "Name for the AI Foundry (Promptflow) Cognitive Services account (must be globally unique, 3-24 lowercase letters/numbers). (Required)"
  type        = string
}

variable "promptflow_subdomain" {
  description = "Custom subdomain for the Promptflow endpoint (must be globally unique, 3-24 lowercase letters/numbers). (Default: schoolgptpf123)"
  type        = string
  default     = "schoolgptpf123"
}

variable "sql_server_name" {
  description = "Azure SQL Server name (must be globally unique, 1-63 lowercase letters/numbers). (Required)"
  type        = string
}

variable "sql_admin" {
  description = "SQL admin username. (Default: sqladminuser)"
  type        = string
  default     = "sqladminuser"
}

variable "sql_password" {
  description = "SQL admin password. (Required, sensitive)"
  type        = string
  sensitive   = true
}

variable "sql_db_name" {
  description = "Azure SQL Database name. (Default: schoolgptdb)"
  type        = string
  default     = "schoolgptdb"
}

variable "app_insights_name" {
  description = "Name for Application Insights resource. (Default: schoolgpt-ai)"
  type        = string
  default     = "schoolgpt-ai"
}

variable "key_vault_name" {
  description = "Name for the Azure Key Vault (must be globally unique, 3-24 alphanumeric characters). (Required)"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID (for Key Vault and access policy). (Required)"
  type        = string
}

variable "key_vault_admin_object_id" {
  description = "Object ID of the Azure AD user or app that should have admin access to the Key Vault. (Required)"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID (Required for provider block)."
  type        = string
} 