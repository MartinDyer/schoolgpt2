terraform {
  backend "azurerm" {
    resource_group_name  = "blundell-production-rg"
    storage_account_name = "blundelltfstatef8b9b7"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
