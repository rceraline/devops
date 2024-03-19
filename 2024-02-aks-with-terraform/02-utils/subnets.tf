data "azurerm_subnet" "utils_01" {
  name                 = "snet-utils-01"
  virtual_network_name = "vnet-aks-01"
  resource_group_name  = data.azurerm_resource_group.rg_01.name
}
