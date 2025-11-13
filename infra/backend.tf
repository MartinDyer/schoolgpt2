terraform {
  backend "azurerm" {
    resource_group_name  = "testscho-production-rg"
    storage_account_name = "testschotfstate028a08"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
