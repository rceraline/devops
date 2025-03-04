data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_subnet" "pe_01" {
  name                 = var.pe_subnet.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.pe_subnet.vnet_name
}

data "azurerm_private_dns_zone" "log" {
  name                = "privatelink.monitor.azure.com"
  resource_group_name = var.resource_group_name
}

data "azurerm_private_dns_zone" "prometheus" {
  name                = "privatelink.canadacentral.prometheus.monitor.azure.com"
  resource_group_name = var.resource_group_name
}


