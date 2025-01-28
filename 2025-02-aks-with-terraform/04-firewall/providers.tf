terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.16.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "faca3dce-cb20-4ceb-9e59-7125faaf8928"
  features {
  }
}
