terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.26.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "{subscription ID}" // update with your subscription ID
  features {
  }
}
