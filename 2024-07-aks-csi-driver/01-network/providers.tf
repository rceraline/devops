terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.110.0"
    }
  }

  backend "azurerm" {
    subscription_id      = "faca3dce-cb20-4ceb-9e59-7125faaf8928"
    resource_group_name  = "rg-tfstate-cac"
    storage_account_name = "sttfstatecac20240212"
    container_name       = "state"
    key                  = "2024-07-aks-csi-driver.network.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "faca3dce-cb20-4ceb-9e59-7125faaf8928"
  features {
  }
}
