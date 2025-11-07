terraform {
  backend "azurerm" {
    resource_group_name  = "luketest-production-rg"
    storage_account_name = "luketesttfstate471e78"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
