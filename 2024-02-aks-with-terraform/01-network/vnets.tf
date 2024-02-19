resource "azurerm_virtual_network" "hub_01" {
  name                = "vnet-hub-01"
  location            = azurerm_resource_group.rg_01.location
  resource_group_name = azurerm_resource_group.rg_01.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network" "aks_01" {
  name                = "vnet-aks-01"
  location            = azurerm_resource_group.rg_01.location
  resource_group_name = azurerm_resource_group.rg_01.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_virtual_network_peering" "hub_01_to_aks_01" {
  name                      = "peer-hub-01-to-aks-01"
  resource_group_name       = azurerm_resource_group.rg_01.name
  virtual_network_name      = azurerm_virtual_network.hub_01.name
  remote_virtual_network_id = azurerm_virtual_network.aks_01.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "aks_01_to_hub_01" {
  name                      = "peer-aks-01-to-hub-01"
  resource_group_name       = azurerm_resource_group.rg_01.name
  virtual_network_name      = azurerm_virtual_network.aks_01.name
  remote_virtual_network_id = azurerm_virtual_network.hub_01.id
  allow_forwarded_traffic   = true
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_01.name
  virtual_network_name = azurerm_virtual_network.hub_01.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "agw_01" {
  name                 = "snet-agw-01"
  resource_group_name  = azurerm_resource_group.rg_01.name
  virtual_network_name = azurerm_virtual_network.aks_01.name
  address_prefixes     = ["10.1.0.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet" "utils_01" {
  name                 = "snet-utils-01"
  resource_group_name  = azurerm_resource_group.rg_01.name
  virtual_network_name = azurerm_virtual_network.aks_01.name
  address_prefixes     = ["10.1.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet" "aks_01" {
  name                 = "snet-aks-01"
  resource_group_name  = azurerm_resource_group.rg_01.name
  virtual_network_name = azurerm_virtual_network.aks_01.name
  address_prefixes     = ["10.1.2.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

