terraform {
  backend "azurerm" {
    resource_group_name   = var.resource_group_name
    storage_account_name  = var.backend_storage_account_name
    container_name        = var.backend_container_name
    key                   = "schoolgpt.terraform.tfstate"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.backend_storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.backend_container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

###############################
# Azure ChatGPT App Template #
###############################

# Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Azure Service Plan (Linux)
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Azure Web App (Linux, Docker)
resource "azurerm_linux_web_app" "main" {
  name                = var.web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  site_config {
    always_on = true
  }
  app_settings = {
    "WEBSITES_PORT"         = "8080"
    # Docker image and registry settings
    "DOCKER_CUSTOM_IMAGE_NAME"        = "${var.acr_login_server}/${var.docker_image}:${var.docker_tag}"
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${var.acr_login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = "<acr-username>" # TODO: Inject from Key Vault or secret
    "DOCKER_REGISTRY_SERVER_PASSWORD" = "<acr-password>" # TODO: Inject from Key Vault or secret
    # App-specific settings
    "PROMPTFLOW_ENDPOINT"             = azurerm_cognitive_account.promptflow.endpoint
    "PROMPTFLOW_API_KEY"              = azurerm_cognitive_account.promptflow.primary_access_key
    "SQL_SERVER"                      = azurerm_mssql_server.main.fully_qualified_domain_name
    "SQL_DB"                          = azurerm_mssql_database.main.name
    "SQL_USER"                        = var.sql_admin
    "SQL_PASSWORD"                    = var.sql_password
    "APPINSIGHTS_INSTRUMENTATIONKEY"  = azurerm_application_insights.main.instrumentation_key
  }
}

# Azure SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password
}

# Azure SQL Database
resource "azurerm_mssql_database" "main" {
  name      = var.sql_db_name
  server_id = azurerm_mssql_server.main.id
  sku_name  = "S0"
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

# AI Foundry (OpenAI) Cognitive Services Account
resource "azurerm_cognitive_account" "promptflow" {
  name                = var.promptflow_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "OpenAI"
  sku_name            = "S0"
  custom_subdomain_name = var.promptflow_subdomain
  identity {
    type = "SystemAssigned"
  }
  tags = {
    environment = "schoolgpt"
  }
}

# Azure Key Vault (for storing ACR credentials)
resource "azurerm_key_vault" "main" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.key_vault_admin_object_id
    secret_permissions = ["Get", "Set", "List"]
  }
  tags = {
    environment = "schoolgpt"
  }
}

# Output connection info for user
output "web_app_url" {
  value = azurerm_linux_web_app.main.default_hostname
}
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}
output "app_insights_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

# Output Promptflow endpoint and key for reference
output "promptflow_endpoint" {
  value = azurerm_cognitive_account.promptflow.endpoint
}
output "promptflow_api_key" {
  value     = azurerm_cognitive_account.promptflow.primary_access_key
  sensitive = true
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "sql_connection_string" {
  value = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin};Password=${var.sql_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive = true
}
