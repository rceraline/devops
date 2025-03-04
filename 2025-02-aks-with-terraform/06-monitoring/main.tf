## Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log" {
  name                = "log-01"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = "ampls-01"
  resource_group_name = data.azurerm_resource_group.rg.name

  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
}

resource "azurerm_monitor_private_link_scoped_service" "log" {
  name                = "amplss-log-01"
  resource_group_name = data.azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.log.id
}

resource "azurerm_private_endpoint" "log" {
  name                = "pe-log-01"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-log-01"
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-log-01"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.log.id]
  }
}


## Azure Monitor Workspace
resource "azurerm_monitor_workspace" "amw" {
  name                = "amw-01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_private_endpoint" "amw" {
  name                = "pe-amw-01"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-amw-01"
    private_connection_resource_id = azurerm_monitor_workspace.amw.id
    subresource_names              = ["prometheusMetrics"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-amw-01"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.prometheus.id]
  }
}
