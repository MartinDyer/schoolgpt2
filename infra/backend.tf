terraform {
  backend "azurerm" {
    resource_group_name  = "luketest-production-rg"
    storage_account_name = "luketesttfstate3d4f41"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
