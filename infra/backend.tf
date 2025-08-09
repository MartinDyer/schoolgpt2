terraform {
  backend "azurerm" {
    resource_group_name  = "testscho-production-rg"
    storage_account_name = "testschotfstatec07383"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
