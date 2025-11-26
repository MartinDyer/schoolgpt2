#################################################################
# School Safe AI App using Azure AI Foundry - Variable Definitions
#################################################################

# Basic Infrastructure Variables
variable "resource_group_name" {
  description = "Name for the Azure Resource Group. (Optional: auto-generated if not provided)"
  type        = string
  default     = null
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
  default     = "SchoolGPT@2024!" # REPLACE: Use a secure password
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


