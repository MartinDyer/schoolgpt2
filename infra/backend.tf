terraform {
  backend "azurerm" {
    resource_group_name  = "school1-production-rg"
    storage_account_name = "school1tfstate34eab7"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
