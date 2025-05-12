terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.16.0"
    }
  }

  backend "azurerm" {
    subscription_id      = "faca3dce-cb20-4ceb-9e59-7125faaf8928"
    resource_group_name  = "rg-tfstate-cac"
    storage_account_name = "sttfstatecac20250502"
    container_name       = "state"
    key                  = "02-dns.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "faca3dce-cb20-4ceb-9e59-7125faaf8928"
  features {
  }
}
