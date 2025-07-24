terraform {
  backend "azurerm" {
    resource_group_name  = var.backend_rg
    storage_account_name = var.backend_storage
    container_name       = var.backend_container
    key                  = var.backend_key
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.backend_storage
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.backend_container
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_app_service_plan" "main" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_linux_web_app" "main" {
  name                = var.web_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_app_service_plan.main.id
  site_config {
    linux_fx_version = "DOCKER|${var.docker_image}:${var.docker_tag}"
  }
  app_settings = {
    "WEBSITES_PORT"         = "8080"
    "AZURE_CLIENT_ID"       = var.azure_client_id
    "AZURE_TENANT_ID"       = var.azure_tenant_id
    "AZURE_SUBSCRIPTION_ID" = var.azure_subscription_id
    "SQL_PASSWORD"          = var.sql_password
    "OPENAI_KEY"            = var.openai_key
    "GPT_ENDPOINT"          = var.gpt_endpoint
    "GPT_DEPLOYMENT"        = var.gpt_deployment
  }
}

resource "azurerm_sql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin
  administrator_login_password = var.sql_password
}

resource "azurerm_sql_database" "main" {
  name                = var.sql_db_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_name         = azurerm_sql_server.main.name
  sku_name            = "S0"
}
