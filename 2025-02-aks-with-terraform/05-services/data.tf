data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_subnet" "pe_01" {
  name                 = var.pe_subnet.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.pe_subnet.vnet_name
}

data "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

data "azurerm_private_dns_zone" "cr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

data "azurerm_private_dns_zone" "st" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}
