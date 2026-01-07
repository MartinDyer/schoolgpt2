terraform {
  backend "azurerm" {
    resource_group_name  = "test1-production-rg"
    storage_account_name = "test1tfstate5b30f7"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
