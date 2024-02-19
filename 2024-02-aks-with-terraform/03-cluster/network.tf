data "azurerm_subnet" "aks_01" {
  name                 = "snet-aks-01"
  virtual_network_name = "vnet-aks-01"
  resource_group_name  = data.azurerm_resource_group.rg_01.name
}

data "azurerm_subnet" "agw_01" {
  name                 = "snet-agw-01"
  virtual_network_name = "vnet-aks-01"
  resource_group_name  = data.azurerm_resource_group.rg_01.name
}

data "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.canadacentral.azmk8s.io"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}
