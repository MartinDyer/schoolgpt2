
# Provider
provider "azurerm" {
  features {}
}

#################################################################
# School Safe AI App using Azure AI Foundry - Simplified Template
#################################################################

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = coalesce(var.resource_group_name, "${replace(lower(var.school_name), " ", "-")}-${var.environment}-rg")
  location = var.location

  tags = {
    Environment = "School-Safe-GPT"
    Project     = "SchoolGPT"
    Purpose     = "Educational AI Platform"
  }
}

###########################################
# AI Foundry with Enhanced Content Filtering
###########################################

# Azure AI Foundry (OpenAI) - School Safe Configuration
resource "azurerm_cognitive_account" "ai_foundry" {
  name                  = var.ai_foundry_name
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = var.ai_foundry_subdomain

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment    = "School-Safe-GPT"
    Purpose        = "AI Foundry for Education"
    ContentFilter  = "High"
    TargetAudience = "Students Under 16"
  }
}

# Content filtering is configured via environment variables in the App Service
# and managed through Azure AI Foundry portal for real-time control

# Model Deployment for School Safe AI
resource "azurerm_cognitive_deployment" "gpt_model" {
  name                 = var.azure_openai_model_deployment_name
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id

  model {
    format  = "OpenAI"
    name    = var.azure_openai_model
    version = var.azure_openai_model_version
  }

  sku {
    name     = var.model_sku_name
    capacity = var.model_capacity
  }
}

###########################################
## App Service
###########################################



# Azure Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = {
    Environment = "School-Safe-GPT"
    Purpose     = "App Hosting"
  }
}

#####################
# Backend Web App
#####################

resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  https_only = true

  site_config {
    # Node runtime for backend API
    application_stack {
      node_version = "18-lts"
    }

    # Allow requests from the frontend app via CORS
    cors {
      allowed_origins = [
        "https://${azurerm_linux_web_app.frontend.default_hostname}"
      ]
      support_credentials = false
    }
  }

  app_settings = {
    # Example: typical Node/Express entry point
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    # Add any backend-specific settings here
    "NODE_ENV"                 = "production"

    # Basic Configuration
    "WEBSITES_PORT"                       = "80"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"

    # Azure AI Foundry Configuration - School Safe Settings
    "AI_FOUNDRY_ENDPOINT"          = azurerm_cognitive_account.ai_foundry.endpoint
    "AI_FOUNDRY_KEY"               = azurerm_cognitive_account.ai_foundry.primary_access_key
    "AI_FOUNDRY_MODEL"             = azurerm_cognitive_deployment.gpt_model.name
    "AI_FOUNDRY_TEMPERATURE"       = "0.1" # Low temperature for consistent, safe responses
    "AI_FOUNDRY_TOP_P"             = "0.9"
    "AI_FOUNDRY_MAX_TOKENS"        = "800" # Controlled response length
    "AI_FOUNDRY_FREQUENCY_PENALTY" = "0.5"
    "AI_FOUNDRY_PRESENCE_PENALTY"  = "0.0"

    # School-Safe System Message with Enhanced Prompt Engineering
    "AI_FOUNDRY_SYSTEM_MESSAGE" = var.school_safe_system_message

    # Application Insights for Monitoring
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string

    # Authentication and Security (Required for School Access)
    "AUTH_ENABLED"     = "true"
    "ENTRA_ID_ENABLED" = "true"

    # School-Specific Settings
    "ENVIRONMENT"          = "SCHOOL_SAFE"
    "TARGET_AUDIENCE"      = "STUDENTS_UNDER_16"
    "CONTENT_MODERATION"   = "HIGH"
    "CHAT_HISTORY_ENABLED" = "true"

    # UI Customization for Schools
    "UI_TITLE"             = var.school_name
    "UI_CHAT_TITLE"        = "School AI Assistant"
    "UI_CHAT_DESCRIPTION"  = "Ask me questions about your studies! I'm here to help with educational content."
    "UI_SHOW_SHARE_BUTTON" = "false" # Disabled for school safety

    # Feature Flags
    "ENABLE_CONTENT_FILTER_LOGGING" = "true"
    "ENABLE_CHAT_HISTORY"           = "true"

    # SQL Connection String
    "SQL_CONNECTION_STRING" = local.sql_connection_string
  }

  # Enable managed identity for secure access
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment    = "School-Safe-GPT"
    Purpose        = "AI Chat Application"
    TargetAudience = "Students Under 16"
  }
}



#####################
# Frontend Web App
#####################

resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only = true

  site_config {
    # Node runtime (if you serve the React build via Node)
    # If you're using something else (e.g. .NET), adjust this.
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "NODE_ENV"                 = "production"

    # 🔗 Link frontend → backend:
    # The frontend can read this env var and call the backend.
    "API_BASE_URL" = "https://${azurerm_linux_web_app.backend.default_hostname}"
     
    # Basic Configuration
    "WEBSITES_PORT"                       = "80"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"

    # Azure AI Foundry Configuration - School Safe Settings
    "AI_FOUNDRY_ENDPOINT"          = azurerm_cognitive_account.ai_foundry.endpoint
    "AI_FOUNDRY_KEY"               = azurerm_cognitive_account.ai_foundry.primary_access_key
    "AI_FOUNDRY_MODEL"             = azurerm_cognitive_deployment.gpt_model.name
    "AI_FOUNDRY_TEMPERATURE"       = "0.1" # Low temperature for consistent, safe responses
    "AI_FOUNDRY_TOP_P"             = "0.9"
    "AI_FOUNDRY_MAX_TOKENS"        = "800" # Controlled response length
    "AI_FOUNDRY_FREQUENCY_PENALTY" = "0.5"
    "AI_FOUNDRY_PRESENCE_PENALTY"  = "0.0"

    # School-Safe System Message with Enhanced Prompt Engineering
    "AI_FOUNDRY_SYSTEM_MESSAGE" = var.school_safe_system_message

    # Application Insights for Monitoring
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string

    # Authentication and Security (Required for School Access)
    "AUTH_ENABLED"     = "true"
    "ENTRA_ID_ENABLED" = "true"

    # School-Specific Settings
    "ENVIRONMENT"          = "SCHOOL_SAFE"
    "TARGET_AUDIENCE"      = "STUDENTS_UNDER_16"
    "CONTENT_MODERATION"   = "HIGH"
    "CHAT_HISTORY_ENABLED" = "true"

    # UI Customization for Schools
    "UI_TITLE"             = var.school_name
    "UI_CHAT_TITLE"        = "School AI Assistant"
    "UI_CHAT_DESCRIPTION"  = "Ask me questions about your studies! I'm here to help with educational content."
    "UI_SHOW_SHARE_BUTTON" = "false" # Disabled for school safety

    # Feature Flags
    "ENABLE_CONTENT_FILTER_LOGGING" = "true"
    "ENABLE_CHAT_HISTORY"           = "true"

    # SQL Connection String
    "SQL_CONNECTION_STRING" = local.sql_connection_string
  }

  # Enable managed identity for secure access
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment    = "School-Safe-GPT"
    Purpose        = "AI Chat Application"
    TargetAudience = "Students Under 16"
  }
}
  

#####################
# Outputs
#####################

output "frontend_url" {
  description = "Public URL of the frontend app"
  value       = "https://${azurerm_linux_web_app.frontend.default_hostname}"
}

output "backend_url" {
  description = "Public URL of the backend app"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}



###########################################
# Application Insights - Enhanced Monitoring
###########################################

# Log Analytics Workspace for Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${replace(azurerm_resource_group.main.name, "_", "-")}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = {
    Environment = "School-Safe-GPT"
    Purpose     = "Centralized Logging"
  }
}

# Application Insights with Enhanced Monitoring
resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  retention_in_days   = 90

  tags = {
    Environment = "School-Safe-GPT"
    Purpose     = "Application Monitoring"
  }
}


###########################################
# Azure Key Vault - Enhanced Security
###########################################

# Azure Key Vault for Secrets Management
resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = var.azure_tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.key_vault_admin_object_id

    secret_permissions = ["Get", "Set", "List", "Delete", "Backup", "Restore", "Purge"]
    key_permissions    = ["Get", "List", "Create", "Delete", "Update", "Purge"]
  }

  # Grant access to the current Azure service principal running Terraform
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "Set", "List", "Delete", "Backup", "Restore", "Purge"]
    key_permissions    = ["Get", "List", "Create", "Delete", "Update", "Purge"]
  }

  tags = {
    Environment = "School-Safe-GPT"
    Purpose     = "Secure Configuration Storage"
  }
}

# Current client for access policy
data "azurerm_client_config" "current" {}

# Store ACR credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = azurerm_container_registry.acr.admin_username
  key_vault_id = azurerm_key_vault.main.id

  tags = {
    Purpose = "Container Registry Access"
  }
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.acr.admin_password
  key_vault_id = azurerm_key_vault.main.id

  tags = {
    Purpose = "Container Registry Access"
  }
}


###########################################
# Azure SQL for Audit Logging / App Data
###########################################

# Auto values for SQL when not provided
locals {
  effective_sql_server_name = var.sql_server_name != null && length(var.sql_server_name) > 0 ? var.sql_server_name : "schoolsql${random_string.suffix.result}"
}

resource "random_password" "sql_admin" {
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true
  # Restrict allowed special characters for broader provider compatibility
  override_special = "!@#%^*-_=+"
}

locals {
  effective_sql_password = var.sql_password != null && length(var.sql_password) > 0 ? var.sql_password : random_password.sql_admin.result
}

# Azure SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = local.effective_sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = local.effective_sql_password

  tags = {
    Environment = "School-Safe-GPT"
    Purpose     = "SQL Server"
  }
}

# Optional Azure AD Admin for SQL Server (removed for provider compatibility)
# Configure AAD admin separately via portal or az CLI if required.

# Azure SQL Database
resource "azurerm_mssql_database" "main" {
  name                = var.sql_db_name
  server_id           = azurerm_mssql_server.main.id
  sku_name            = var.sql_sku_name
  max_size_gb         = 2
  zone_redundant      = false
  auto_pause_delay_in_minutes = -1

  tags = {
    Environment = "School-Safe-GPT"
    Purpose     = "Application Database"
  }
}

# Build SQL connection string
locals {
  sql_connection_string = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin};Password=${local.effective_sql_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

# Store SQL connection string in Key Vault
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  value        = local.sql_connection_string
  key_vault_id = azurerm_key_vault.main.id

  tags = {
    Purpose = "Application Database"
  }

  lifecycle {
    ignore_changes = [ value ]
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Null resource to handle Key Vault secret purging if needed
resource "null_resource" "key_vault_cleanup" {
  provisioner "local-exec" {
    command = "echo 'Key Vault cleanup completed'"
  }

  depends_on = [
    azurerm_key_vault.main
  ]
}

###########################################
# Outputs - Enhanced Information
###########################################

output "deployment_summary" {
  value = {
    web_app_url           = "https://${azurerm_linux_web_app.main.default_hostname}"
    ai_foundry_endpoint   = azurerm_cognitive_account.ai_foundry.endpoint
    ai_model_deployment   = azurerm_cognitive_deployment.gpt_model.name
    container_registry    = azurerm_container_registry.acr.login_server
    application_insights  = azurerm_application_insights.main.name
    key_vault             = azurerm_key_vault.main.name
    resource_group        = azurerm_resource_group.main.name
    database               = azurerm_mssql_database.main.name
  }
}

output "school_safe_configuration" {
  value = {
    content_filter_level = "HIGH"
    target_audience      = "Students Under 16"
    authentication       = "Entra ID Required"
    monitoring_enabled   = "Yes"
    chat_history         = "Azure SQL"
    user_management      = "Entra ID"
  }
}

output "next_steps" {
  value = [
    "1. Configure Entra ID authentication in Azure Portal",
    "2. Deploy model to AI Foundry endpoint: ${azurerm_cognitive_account.ai_foundry.endpoint}",
    "3. Push application code to trigger GitHub Actions deployment",
    "4. Configure content filter policies in AI Foundry portal",
    "5. Test application with school-appropriate content"
  ]
}

# Additional outputs for CI/CD workflows


output "web_app_name" {
  value = azurerm_linux_web_app.main.name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

# Sensitive outputs
output "ai_foundry_api_key" {
  value     = azurerm_cognitive_account.ai_foundry.primary_access_key
  sensitive = true
}


# Output for SQL connection string (sensitive)
output "sql_connection_string" {
  value     = azurerm_key_vault_secret.sql_connection_string.value
  sensitive = true
}
