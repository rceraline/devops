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

data "azurerm_log_analytics_workspace" "log" {
  resource_group_name = var.resource_group_name
  name                = var.log_analytics_workspace_name
}

data "azurerm_key_vault" "kv" {
  resource_group_name = var.resource_group_name
  name                = var.key_vault_name
}

data "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.canadacentral.azmk8s.io"
  resource_group_name = var.resource_group_name
}

data "azurerm_private_dns_zone" "mydomain" {
  name                = "mydomain.com"
  resource_group_name = var.resource_group_name
}

data "azurerm_dashboard_grafana" "grafana" {
  resource_group_name = var.resource_group_name
  name                = var.grafana_dashboard_name
}

data "azurerm_monitor_workspace" "amw" {
  resource_group_name = var.resource_group_name
  name                = var.monitor_workspace_name
}

data "azurerm_monitor_data_collection_endpoint" "dce_prometheus" {
  name                = "MSProm-aks-01"
  resource_group_name = data.azurerm_resource_group.rg.name
}
