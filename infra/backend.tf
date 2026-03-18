terraform {
  backend "azurerm" {
    resource_group_name  = "luketest-production-rg"
    storage_account_name = "luketesttfstate78780f"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
