data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "dnsinbound" {
  name                 = var.dnsinbound_subnet_name
  virtual_network_name = var.hub_vnet_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_virtual_network" "all_vnets" {
  for_each = var.all_vnet_names

  name                = each.key
  resource_group_name = var.resource_group_name
}
