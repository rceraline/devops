resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.canadacentral.azmk8s.io"
  resource_group_name = azurerm_resource_group.rg_01.name
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.rg_01.name
}

resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg_01.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "link-to-aks"
  resource_group_name   = azurerm_resource_group.rg_01.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.aks_01.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "link-to-acr"
  resource_group_name   = azurerm_resource_group.rg_01.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.aks_01.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  name                  = "link-to-vault"
  resource_group_name   = azurerm_resource_group.rg_01.name
  private_dns_zone_name = azurerm_private_dns_zone.vault.name
  virtual_network_id    = azurerm_virtual_network.aks_01.id
}
