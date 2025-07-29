
# Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

#################################################################
# School Safe AI App using Azure AI Foundry - Simplified Template
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

# Enhanced Content Filter Configuration
resource "azurerm_cognitive_account_content_filter" "school_safe_filters" {
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id
  
  # Hate Speech Filter
  hate {
    enabled = true
    severity = var.content_filter_hate_severity
  }
  
  # Sexual Content Filter
  sexual {
    enabled = true
    severity = var.content_filter_sexual_severity
  }
  
  # Violence Filter
  violence {
    enabled = true
    severity = var.content_filter_violence_severity
  }
  
  # Self-Harm Filter
  self_harm {
    enabled = true
    severity = var.content_filter_self_harm_severity
  }
  
  # Custom Content Filter Rules (Conditional)
  dynamic "custom_filters" {
    for_each = var.enable_custom_content_filters ? [1] : []
    content {
      name = "school_safe_vocabulary"
      enabled = true
      severity = "Medium"
      patterns = var.custom_filter_patterns
    }
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

# Azure Web App with Simplified Configuration
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
    "AI_FOUNDRY_ENDPOINT"     = azurerm_cognitive_account.ai_foundry.endpoint
    "AI_FOUNDRY_KEY"          = azurerm_cognitive_account.ai_foundry.primary_access_key
    "AI_FOUNDRY_MODEL"        = azurerm_cognitive_deployment.gpt_model.name
    "AI_FOUNDRY_TEMPERATURE"  = "0.1"  # Low temperature for consistent, safe responses
    "AI_FOUNDRY_TOP_P"        = "0.9"
    "AI_FOUNDRY_MAX_TOKENS"   = "800"  # Controlled response length
    "AI_FOUNDRY_FREQUENCY_PENALTY" = "0.5"
    "AI_FOUNDRY_PRESENCE_PENALTY"  = "0.0"
    
    # School-Safe System Message with Enhanced Prompt Engineering
    "AI_FOUNDRY_SYSTEM_MESSAGE" = var.school_safe_system_message
    
    # Content Filter Settings (High Level for School Safety)
    "AI_FOUNDRY_CONTENT_FILTER_HATE"     = "2"  # High filtering
    "AI_FOUNDRY_CONTENT_FILTER_SEXUAL"   = "2"  # High filtering  
    "AI_FOUNDRY_CONTENT_FILTER_VIOLENCE" = "2"  # High filtering
    "AI_FOUNDRY_CONTENT_FILTER_SELF_HARM" = "2"  # High filtering
    
    # Table Storage Configuration for Chat History
    "TABLE_STORAGE_CONNECTION_STRING" = azurerm_storage_account.chat_history.primary_connection_string
    "TABLE_STORAGE_CONVERSATIONS_TABLE" = "conversations"
    "TABLE_STORAGE_MESSAGES_TABLE" = "messages"
    "TABLE_STORAGE_ENABLE_FEEDBACK" = "false"
    
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
    "CHAT_HISTORY_ENABLED" = "true"
    
    # UI Customization for Schools
    "UI_TITLE" = var.school_name
    "UI_CHAT_TITLE" = "School AI Assistant"
    "UI_CHAT_DESCRIPTION" = "Ask me questions about your studies! I'm here to help with educational content."
    "UI_SHOW_SHARE_BUTTON" = "false"  # Disabled for school safety
    
    # Feature Flags
    "ENABLE_CONTENT_FILTER_LOGGING" = "true"
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
# Azure Table Storage for Chat History
###########################################

# Storage account for chat history (Table Storage)
resource "azurerm_storage_account" "chat_history" {
  name                     = "schoolchat${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  tags = {
    Environment = "School-Safe-AI"
    Purpose     = "Chat History Storage"
  }
}

# Table for storing conversations
resource "azurerm_storage_table" "conversations" {
  name                 = "conversations"
  storage_account_name = azurerm_storage_account.chat_history.name
}

# Table for storing messages
resource "azurerm_storage_table" "messages" {
  name                 = "messages"
  storage_account_name = azurerm_storage_account.chat_history.name
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

# Store Table Storage connection string in Key Vault
resource "azurerm_key_vault_secret" "table_storage_connection_string" {
  name         = "table-storage-connection-string"
  value        = azurerm_storage_account.chat_history.primary_connection_string
  key_vault_id = azurerm_key_vault.main.id
  
  tags = {
    Purpose = "Chat History Storage"
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
    container_registry       = azurerm_container_registry.acr.login_server
    application_insights     = azurerm_application_insights.main.name
    key_vault               = azurerm_key_vault.main.name
    resource_group          = azurerm_resource_group.main.name
    table_storage_account    = azurerm_storage_account.chat_history.name
  }
}

output "school_safe_configuration" {
  value = {
    content_filter_level = "HIGH"
    target_audience     = "Students Under 16"
    authentication      = "Entra ID Required"
    monitoring_enabled  = "Yes"
    chat_history       = "Table Storage"
    user_management    = "Entra ID"
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

output "table_storage_connection_string" {
  value     = azurerm_key_vault_secret.table_storage_connection_string.value
  sensitive = true
}

output "table_storage_account_name" {
  value = azurerm_storage_account.chat_history.name
}

output "container_registry_credentials" {
  value = {
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }
  sensitive = true
}
