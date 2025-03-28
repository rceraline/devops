data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_container_registry" "cr" {
  name                = var.container_registry_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "nodes" {
  name                 = var.aks_nodes_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.aks_vnet_name
}

data "azurerm_subnet" "pe_01" {
  name                 = var.pe_subnet.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.pe_subnet.vnet_name
}

data "azurerm_key_vault" "kv" {
  resource_group_name = var.resource_group_name
  name                = var.key_vault_name
}

data "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.canadacentral.azmk8s.io"
  resource_group_name = var.resource_group_name
}

data "azurerm_private_dns_zone" "grafana" {
  name                = "privatelink.grafana.azure.com"
  resource_group_name = var.resource_group_name
}

data "azurerm_private_dns_zone" "prometheus" {
  name                = "privatelink.canadacentral.prometheus.monitor.azure.com"
  resource_group_name = var.resource_group_name
}

data "azurerm_private_dns_zone" "mydomain" {
  name                = "mydomain.com"
  resource_group_name = var.resource_group_name
}

## AMPLS zones
data "azurerm_private_dns_zone" "ampls" {
  for_each = toset([
    "privatelink.blob.core.windows.net",
    "privatelink.monitor.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net"
  ])

  name                = each.key
  resource_group_name = var.resource_group_name
}
