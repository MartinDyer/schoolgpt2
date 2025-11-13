terraform {
  backend "azurerm" {
    resource_group_name  = "Management"
    storage_account_name = "tfstatelax"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}