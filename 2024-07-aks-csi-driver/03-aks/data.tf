data "azurerm_resource_group" "rg" {
  name = "rg-csi-driver-01"
}

data "azurerm_private_dns_zone" "cr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.canadacentral.azmk8s.io"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "utilities_01" {
  name                 = "snet-utilities-01"
  virtual_network_name = "vnet-csi-driver-01"
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "aks" {
  name                 = "snet-aks-01"
  virtual_network_name = "vnet-csi-driver-01"
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_container_registry" "cr" {
  name                = "cr20240701"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_client_config" "current" {}
