terraform {
  backend "azurerm" {
    resource_group_name  = "blundell-production-rg"
    storage_account_name = "blundelltfstate041a21"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
