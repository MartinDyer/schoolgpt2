terraform {
  backend "azurerm" {
    resource_group_name  = "luketest-production-rg"
    storage_account_name = "luketesttfstate022856"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
