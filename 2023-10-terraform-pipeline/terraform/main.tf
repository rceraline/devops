terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.74.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-cac"
    storage_account_name = "satfstatecac20230510"
    container_name       = "state"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-01"
  location = "Canada Central"
}
