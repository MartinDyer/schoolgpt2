terraform {
  backend "azurerm" {
    resource_group_name  = "schoolgpt-rg"
    storage_account_name = "schoolgpttfstate8aa5cd"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
