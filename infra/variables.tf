#################################################################
# School Safe AI App using Azure AI Foundry - Variable Definitions
#################################################################

# Basic Infrastructure Variables
variable "resource_group_name" {
  description = "Name for the Azure Resource Group. (Required)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources (e.g., eastus, uksouth). (Default: uksouth)"
  type        = string
  default     = "uksouth"
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID (for Key Vault and access policy). (Required)"
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
  default     = "School AI Assistant"
}

variable "alert_email" {
  description = "Email address for receiving alerts about content filter violations and system issues. (Required)"
  type        = string
}

# Azure AI Foundry Configuration
variable "ai_foundry_name" {
  description = "Name for the Azure AI Foundry (OpenAI) resource (must be globally unique, 3-24 lowercase letters/numbers). (Required)"
  type        = string
}

variable "ai_foundry_subdomain" {
  description = "Custom subdomain for the AI Foundry endpoint (must be globally unique, 3-24 lowercase letters/numbers). (Required)"
  type        = string
}

variable "azure_openai_model" {
  description = "Azure OpenAI model name for AI Foundry (e.g., gpt-35-turbo, gpt-4, gpt-4o). (Default: gpt-35-turbo)"
  type        = string
  default     = "gpt-35-turbo"

  validation {
    condition = contains([
      "gpt-35-turbo",
      "gpt-35-turbo-16k",
      "gpt-4",
      "gpt-4-32k",
      "gpt-4o",
      "gpt-4-turbo"
    ], var.azure_openai_model)
    error_message = "Model must be one of: gpt-35-turbo, gpt-35-turbo-16k, gpt-4, gpt-4-32k, gpt-4o, gpt-4-turbo"
  }
}

variable "azure_openai_model_version" {
  description = "Version of the Azure OpenAI model. (Default: 0613 for GPT-3.5-turbo)"
  type        = string
  default     = "0613"
}

variable "azure_openai_model_deployment_name" {
  description = "Name for the model deployment in AI Foundry. (Default: school-safe-chat)"
  type        = string
  default     = "school-safe-chat"
}

variable "model_sku_name" {
  description = "SKU name for the model deployment (Standard for most use cases). (Default: Standard)"
  type        = string
  default     = "Standard"
}

variable "model_capacity" {
  description = "Capacity for the model deployment (tokens per minute). (Default: 120)"
  type        = number
  default     = 120

  validation {
    condition     = var.model_capacity >= 1 && var.model_capacity <= 1000
    error_message = "Model capacity must be between 1 and 1000."
  }
}

# School-Safe System Message with Enhanced Prompt Engineering
variable "school_safe_system_message" {
  description = "System message for school-safe AI interactions with enhanced prompt engineering for students under 16."
  type        = string
  default     = "You are a helpful, safe, and educational AI assistant designed specifically for students under the age of 16. Your role is to:\n\n1. Provide accurate, age-appropriate educational content\n2. Encourage learning, critical thinking, and curiosity\n3. Maintain a supportive and positive tone\n4. Refuse to discuss or provide information about inappropriate topics including violence, explicit content, harmful activities, or anything not suitable for minors\n5. Guide students toward reliable educational resources\n6. Promote digital citizenship and online safety\n7. Encourage students to verify information with teachers and trusted sources\n\nWhen responding:\n- Use clear, simple language appropriate for the student's age\n- Provide educational value in every response\n- Encourage further learning and exploration of appropriate topics\n- If asked about inappropriate content, politely redirect to educational alternatives\n- Always prioritize the student's safety, well-being, and educational development\n\nRemember: The user is under 16 years old and requires high-integrity, safe, and educational responses."
}

# Container Registry Configuration  
variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique, 5-50 lowercase letters/numbers). (Required)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must be 5-50 characters, lowercase letters and numbers only."
  }
}

variable "acr_login_server" {
  description = "Login server for the Azure Container Registry (e.g., myacr.azurecr.io). (Auto-derived, can be left blank)"
  type        = string
  default     = ""
}

# App Service Configuration
variable "app_service_plan_name" {
  description = "Name for the App Service Plan. (Default: schoolgpt-asp)"
  type        = string
  default     = "schoolgpt-asp"
}

variable "app_service_sku" {
  description = "SKU for the App Service Plan (B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2). (Default: B2)"
  type        = string
  default     = "B2"

  validation {
    condition = contains([
      "B1", "B2", "B3",
      "S1", "S2", "S3",
      "P1v2", "P2v2", "P3v2"
    ], var.app_service_sku)
    error_message = "App Service SKU must be one of: B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2"
  }
}

variable "web_app_name" {
  description = "Name for the Azure Web App (must be globally unique). (Required)"
  type        = string

  validation {
    condition     = length(var.web_app_name) >= 2 && length(var.web_app_name) <= 60
    error_message = "Web app name must be between 2 and 60 characters."
  }
}

# Docker Configuration
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

# Application Insights Configuration
variable "app_insights_name" {
  description = "Name for Application Insights resource. (Default: schoolgpt-ai)"
  type        = string
  default     = "schoolgpt-ai"
}

# Key Vault Configuration
variable "key_vault_name" {
  description = "Name for the Azure Key Vault (must be globally unique, 3-24 alphanumeric characters). (Required)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Key Vault name must be 3-24 characters, letters, numbers, and hyphens only."
  }
}

variable "key_vault_admin_object_id" {
  description = "Object ID of the Azure AD user or app that should have admin access to the Key Vault. (Required)"
  type        = string
}

# Content filtering is managed through Azure AI Foundry portal
# and configured via environment variables in the application 

# Azure SQL Configuration
variable "sql_server_name" {
  description = "Name for the Azure SQL Server (must be globally unique within Azure). If not provided, a name will be auto-generated."
  type        = string
  default     = null
}

variable "sql_admin" {
  description = "Administrator login name for Azure SQL Server. (Default: sqladminuser)"
  type        = string
  default     = "sqladminuser"
}

variable "sql_password" {
  description = "Administrator login password for Azure SQL Server. If not provided, a strong password will be auto-generated and stored in Key Vault."
  type        = string
  default     = null
}

variable "sql_db_name" {
  description = "Name of the Azure SQL Database. (Default: schoolgptdb)"
  type        = string
  default     = "schoolgptdb"
}

variable "sql_sku_name" {
  description = "SKU/edition for the Azure SQL Database (e.g., Basic, S0, S1, S2, S3). (Default: S1)"
  type        = string
  default     = "S1"
}

variable "sql_azuread_admin_login" {
  description = "Azure AD admin login (UPN/email) for the SQL Server (optional)."
  type        = string
  default     = null
}

variable "sql_azuread_admin_object_id" {
  description = "Azure AD admin object ID for the SQL Server (optional)."
  type        = string
  default     = null
} 