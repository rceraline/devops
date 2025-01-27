data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_subnet" "gateway" {
  name                 = var.gateway_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.hub_vnet_name
}
