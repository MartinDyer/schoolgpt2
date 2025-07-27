terraform {
  backend "azurerm" {
    resource_group_name  = "schoolgpt-rg"
    storage_account_name = "testingstfstate7a1124"
    container_name       = "tfstate"
    key                  = "production.terraform.tfstate"
  }
}
