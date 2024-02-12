terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">="
    }
  }

  backend "azurerm" {
    subscription_id      = ""
    resource_group_name  = ""
    storage_account_name = ""
    container_name       = "state"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = ""
  features {
  }
}
