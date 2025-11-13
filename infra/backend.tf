terraform {
  backend "azurerm" {
    resource_group_name  = "luketest-production-rg"
    storage_account_name = "luketesttfstatea425a7"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
