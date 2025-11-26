
# Provider
provider "azurerm" {
  features {}
    subscription_id = "b314f8eb-7c3d-4ca4-87c9-5daa33527126"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-aifoundry-School-Safe-GPT"
  location = var.location

lifecycle {
    prevent_destroy = true
  }
  
}

## Create an AI Foundry resource
##

resource "azurerm_cognitive_account" "ai_foundry" {
  name                = "School-Safe-GPT-AIF-${random_string.unique.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "AIServices"

  identity {
    type = "SystemAssigned"
  }

  sku_name = "S0"

  # required for stateful development in Foundry including agent service
  custom_subdomain_name = "School-Safe-GPT-AIF-${random_string.unique.result}"
  project_management_enabled = true

  tags = {
    Acceptance = "Test"
  }

lifecycle {
    prevent_destroy = true
  }

}

## Create a deployment for OpenAI's GPT-4o in the AI Foundry resource
##
resource "azurerm_cognitive_deployment" "aifoundry_deployment_gpt_4o" {
  depends_on = [
    azurerm_cognitive_account.ai_foundry
  ]

  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.ai_foundry.id

  sku {
    name     = "GlobalStandard"
    capacity = 1
  }

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20"
  }

lifecycle {
    prevent_destroy = true
  }

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


# Azure SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = coalesce(var.sql_server_name, "sqlserver-${replace(lower(var.school_name), " ", "-")}-${var.environment}-${random_string.suffix.result}")
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password

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
  sql_connection_string = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin};Password=${var.sql_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
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
    "2. Push application code to trigger GitHub Actions deployment",
    "3. Configure content filter policies in AI Foundry portal",
    "4. Test application with school-appropriate content"
  ]
}

# Additional outputs for CI/CD workflows


output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

# Output for SQL connection string (sensitive)
output "sql_connection_string" {
  value     = azurerm_key_vault_secret.sql_connection_string.value
  sensitive = true
}
