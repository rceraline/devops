## Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log" {
  name                = var.log_analytics_workspace_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = var.monitor_private_link_scope_name
  resource_group_name = data.azurerm_resource_group.rg.name

  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
}

resource "azurerm_monitor_private_link_scoped_service" "log" {
  name                = var.monitor_private_link_scoped_service_name
  resource_group_name = data.azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.log.id
}

resource "azurerm_private_endpoint" "log" {
  name                = "pe-${var.log_analytics_workspace_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-${var.log_analytics_workspace_name}"
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.log_analytics_workspace_name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.log.id]
  }
}


## Azure Monitor Workspace
resource "azurerm_monitor_workspace" "amw" {
  name                = var.monitor_workspace_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_private_endpoint" "amw" {
  name                = "pe-${var.monitor_workspace_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-${var.monitor_workspace_name}"
    private_connection_resource_id = azurerm_monitor_workspace.amw.id
    subresource_names              = ["prometheusMetrics"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.monitor_workspace_name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.prometheus.id]
  }
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                  = var.grafana_dashboard_name
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  grafana_major_version = 10

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.amw.id
  }
}

resource "azurerm_role_assignment" "datareaderrole" {
  scope                = azurerm_monitor_workspace.amw.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}

resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_id
}
