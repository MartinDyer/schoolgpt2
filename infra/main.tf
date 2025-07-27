
# Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

#################################################################
# School Safe AI App using Azure AI Foundry - Complete Template
#################################################################

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    Environment = "School-Safe-AI"
    Project     = "SchoolGPT"
    Purpose     = "Educational AI Platform"
  }
}

# Terraform State Storage Account
# resource "azurerm_storage_account" "tfstate" {
#   name                     = var.backend_storage_account_name
#   resource_group_name      = azurerm_resource_group.main.name
#   location                 = azurerm_resource_group.main.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   min_tls_version          = "TLS1_2"
#   
#   tags = {
#     Environment = "School-Safe-AI"
#     Purpose     = "Terraform State Storage"
#   }
# }
# 
# resource "azurerm_storage_container" "tfstate" {
#   name                  = var.backend_container_name
#   storage_account_id    = azurerm_storage_account.tfstate.id
#   container_access_type = "private"
# }

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
    Environment = "School-Safe-AI"
    Purpose     = "AI Foundry for Education"
    ContentFilter = "High"
    TargetAudience = "Students Under 16"
  }
}

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
    name = var.model_sku_name
    capacity = var.model_capacity
  }
}

###########################################
# Container Registry and App Service
###########################################

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = true
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "Docker Images"
  }
}

# Azure Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "App Hosting"
  }
}

# Azure Web App with Enhanced School-Safe Configuration
resource "azurerm_linux_web_app" "main" {
  name                = var.web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  
  site_config {
    always_on = true
    ftps_state = "Disabled"
    application_stack {
      docker_image_name        = "${var.docker_image}:${var.docker_tag}"
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }
  }
  
  app_settings = {
    # Basic Configuration
    "WEBSITES_PORT" = "80"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    
    # Docker Configuration
    "DOCKER_ENABLE_CI" = "true"
    "DOCKER_CUSTOM_IMAGE_NAME" = "${var.acr_login_server}/${var.docker_image}:${var.docker_tag}"
    
    # Azure AI Foundry Configuration - School Safe Settings
    "AZURE_OPENAI_ENDPOINT"     = azurerm_cognitive_account.ai_foundry.endpoint
    "AZURE_OPENAI_KEY"          = azurerm_cognitive_account.ai_foundry.primary_access_key
    "AZURE_OPENAI_MODEL"        = azurerm_cognitive_deployment.gpt_model.name
    "AZURE_OPENAI_TEMPERATURE"  = "0.1"  # Low temperature for consistent, safe responses
    "AZURE_OPENAI_TOP_P"        = "0.9"
    "AZURE_OPENAI_MAX_TOKENS"   = "800"  # Controlled response length
    "AZURE_OPENAI_FREQUENCY_PENALTY" = "0.5"
    "AZURE_OPENAI_PRESENCE_PENALTY"  = "0.0"
    
    # School-Safe System Message with Enhanced Prompt Engineering
    "AZURE_OPENAI_SYSTEM_MESSAGE" = var.school_safe_system_message
    
    # Content Filter Settings (High Level for School Safety)
    "AZURE_OPENAI_CONTENT_FILTER_HATE"     = "2"  # High filtering
    "AZURE_OPENAI_CONTENT_FILTER_SEXUAL"   = "2"  # High filtering  
    "AZURE_OPENAI_CONTENT_FILTER_VIOLENCE" = "2"  # High filtering
    "AZURE_OPENAI_CONTENT_FILTER_SELF_HARM" = "2"  # High filtering
    
    # Database Configuration for Chat History and Audit
    "AZURE_SQL_SERVER"   = azurerm_mssql_server.main.fully_qualified_domain_name
    "AZURE_SQL_DATABASE" = azurerm_mssql_database.main.name
    "AZURE_SQL_USERNAME" = var.sql_admin
    "AZURE_SQL_PASSWORD" = var.sql_password
    "AZURE_SQL_CONNECTION_STRING" = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin};Password=${var.sql_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    # Application Insights for Monitoring
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    
    # Authentication and Security (Required for School Access)
    "AUTH_ENABLED" = "true"
    "ENTRA_ID_ENABLED" = "true"
    
    # School-Specific Settings
    "ENVIRONMENT" = "SCHOOL_SAFE"
    "TARGET_AUDIENCE" = "STUDENTS_UNDER_16"
    "CONTENT_MODERATION" = "HIGH"
    "AUDIT_ENABLED" = "true"
    "CHAT_HISTORY_ENABLED" = "true"
    
    # UI Customization for Schools
    "UI_TITLE" = var.school_name
    "UI_CHAT_TITLE" = "School AI Assistant"
    "UI_CHAT_DESCRIPTION" = "Ask me questions about your studies! I'm here to help with educational content."
    "UI_SHOW_SHARE_BUTTON" = "false"  # Disabled for school safety
    
    # Feature Flags
    "ENABLE_CONTENT_FILTER_LOGGING" = "true"
    "ENABLE_AUDIT_LOGGING" = "true"
    "ENABLE_CHAT_HISTORY" = "true"
  }
  
  # Enable managed identity for secure access
  identity {
    type = "SystemAssigned"
  }
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "AI Chat Application"
    TargetAudience = "Students Under 16"
  }
}

###########################################
# Azure SQL Database - Enhanced Schema
###########################################

# Azure SQL Server with Enhanced Security
resource "azurerm_mssql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password
  minimum_tls_version          = "1.2"
  
  azuread_administrator {
    login_username = var.sql_azuread_admin_login
    object_id      = var.sql_azuread_admin_object_id
  }
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "Chat History and Audit Storage"
  }
}

# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Azure SQL Database
resource "azurerm_mssql_database" "main" {
  name      = var.sql_db_name
  server_id = azurerm_mssql_server.main.id
  sku_name  = var.sql_sku_name
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "Chat Data Storage"
  }
}

###########################################
# Application Insights - Enhanced Monitoring
###########################################

# Log Analytics Workspace for Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.resource_group_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  
  tags = {
    Environment = "School-Safe-AI"
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
    Environment = "School-Safe-AI"
    Purpose     = "Application Monitoring"
  }
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "school_alerts" {
  name                = "school-ai-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "SchoolAI"
  
  email_receiver {
    name          = "School IT Admin"
    email_address = var.alert_email
  }
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "Alert Notifications"
  }
}

# Content Filter Alert (will be added after deployment when metrics exist)
# resource "azurerm_monitor_metric_alert" "content_filter_alert" {
#   name                = "content-filter-violations"
#   resource_group_name = azurerm_resource_group.main.name
#   scopes              = [azurerm_application_insights.main.id]
#   description         = "Alert when content filter is triggered"
# }

###########################################
# Azure Key Vault - Enhanced Security
###########################################

# Azure Key Vault for Secrets Management
resource "azurerm_key_vault" "main" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
  
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.key_vault_admin_object_id
    
    secret_permissions = ["Get", "Set", "List", "Delete", "Backup", "Restore"]
    key_permissions    = ["Get", "List", "Create", "Delete", "Update"]
  }
  
  # Grant access to Web App managed identity
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = azurerm_linux_web_app.main.identity[0].principal_id
    
    secret_permissions = ["Get", "List"]
  }
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "Secure Configuration Storage"
  }
}

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

# Store database connection string
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin};Password=${var.sql_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.main.id
  
  tags = {
    Purpose = "Database Connection"
  }
}

###########################################
# Database Schema Initialization
###########################################

# SQL Script for creating school-safe database schema
resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id = azurerm_mssql_database.main.id
  
  storage_endpoint                        = azurerm_storage_account.audit_logs.primary_blob_endpoint
  storage_account_access_key             = azurerm_storage_account.audit_logs.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                      = 90
}

# Storage account for audit logs
resource "azurerm_storage_account" "audit_logs" {
  name                     = "schoolaudit${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "Audit Log Storage"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

###########################################
# Outputs - Enhanced Information
###########################################

output "deployment_summary" {
  value = {
    web_app_url              = "https://${azurerm_linux_web_app.main.default_hostname}"
    ai_foundry_endpoint      = azurerm_cognitive_account.ai_foundry.endpoint
    ai_model_deployment      = azurerm_cognitive_deployment.gpt_model.name
    database_server          = azurerm_mssql_server.main.fully_qualified_domain_name
    container_registry       = azurerm_container_registry.acr.login_server
    application_insights     = azurerm_application_insights.main.name
    key_vault               = azurerm_key_vault.main.name
    resource_group          = azurerm_resource_group.main.name
  }
}

output "school_safe_configuration" {
  value = {
    content_filter_level = "HIGH"
    target_audience     = "Students Under 16"
    authentication      = "Entra ID Required"
    monitoring_enabled  = "Yes"
    audit_logging      = "Yes"
    chat_history       = "Yes"
  }
}

output "next_steps" {
  value = [
    "1. Configure Entra ID authentication in Azure Portal",
    "2. Deploy model to AI Foundry endpoint: ${azurerm_cognitive_account.ai_foundry.endpoint}",
    "3. Run database schema initialization script",
    "4. Push application code to trigger GitHub Actions deployment",
    "5. Configure content filter policies in AI Foundry portal",
    "6. Test application with school-appropriate content"
  ]
}

# Additional outputs for CI/CD workflows
output "container_registry_name" {
  value = azurerm_container_registry.acr.name
}

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

output "sql_connection_string" {
  value     = azurerm_key_vault_secret.sql_connection_string.value
  sensitive = true
}

output "container_registry_credentials" {
  value = {
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }
  sensitive = true
}
