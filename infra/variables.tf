variable "backend_rg" {
  description = "Resource group for Terraform backend state storage"
  type        = string
}

variable "backend_storage" {
  description = "Storage account name for Terraform backend state"
  type        = string
}

variable "backend_container" {
  description = "Storage container name for Terraform backend state"
  type        = string
}

variable "backend_key" {
  description = "Key (file name) for Terraform state file"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the main resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
}

variable "web_app_name" {
  description = "Name of the Linux Web App"
  type        = string
}

variable "docker_image" {
  description = "Docker image name for the app"
  type        = string
}

variable "docker_tag" {
  description = "Docker image tag for the app"
  type        = string
}

variable "azure_client_id" {
  description = "Azure Client ID for MSAL auth"
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID for Entra ID auth"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID for infra access"
  type        = string
  sensitive   = true
}

variable "sql_server_name" {
  description = "Azure SQL Server name"
  type        = string
}

variable "sql_admin" {
  description = "SQL admin username"
  type        = string
}

variable "sql_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true
}

variable "sql_db_name" {
  description = "Azure SQL Database name"
  type        = string
}

variable "openai_key" {
  description = "Azure OpenAI API key"
  type        = string
  sensitive   = true
}

variable "gpt_endpoint" {
  description = "Azure OpenAI endpoint URL"
  type        = string
}

variable "gpt_deployment" {
  description = "Azure OpenAI deployment name"
  type        = string
} 