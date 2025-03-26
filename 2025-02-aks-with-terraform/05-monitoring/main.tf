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

## WORKAROUND: wait a couple of seconds before creating the AMPLS private endpoint
resource "time_sleep" "ampls_wait" {
  create_duration = "10s"
  depends_on      = [azurerm_monitor_private_link_scope.ampls]
}

resource "azurerm_private_endpoint" "ampls" {
  name                = "pe-${var.monitor_private_link_scope_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-${var.monitor_private_link_scope_name}"
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.monitor_private_link_scope_name}"
    private_dns_zone_ids = [for zone in data.azurerm_private_dns_zone.ampls : zone.id]
  }

  depends_on = [time_sleep.ampls_wait]
}

## prometheus
resource "azurerm_monitor_data_collection_endpoint" "dce_prometheus" {
  name                          = "MSProm-aks-01"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  kind                          = "Linux"
  public_network_access_enabled = false
}

resource "azurerm_monitor_private_link_scoped_service" "dce_prometheus" {
  name                = "link-prometheus-aks-01"
  resource_group_name = data.azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce_prometheus.id
}

## Azure Monitor Workspace
resource "azurerm_monitor_workspace" "amw" {
  name                          = var.monitor_workspace_name
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  public_network_access_enabled = false
}

resource "azurerm_monitor_private_link_scoped_service" "amw" {
  name                = "link-${var.monitor_workspace_name}"
  resource_group_name = data.azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_monitor_workspace.amw.default_data_collection_endpoint_id
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

## grafana
resource "azurerm_dashboard_grafana" "grafana" {
  name                          = var.grafana_dashboard_name
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  grafana_major_version         = 10
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.amw.id
  }
}

resource "azurerm_private_endpoint" "grafana" {
  name                = "pe-${var.grafana_dashboard_name}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.pe_01.id

  private_service_connection {
    name                           = "psc-${var.grafana_dashboard_name}"
    private_connection_resource_id = azurerm_dashboard_grafana.grafana.id
    subresource_names              = ["grafana"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-${var.grafana_dashboard_name}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.grafana.id]
  }
}

resource "azurerm_dashboard_grafana_managed_private_endpoint" "amw" {
  grafana_id                   = azurerm_dashboard_grafana.grafana.id
  name                         = "mpe-${var.monitor_workspace_name}"
  location                     = data.azurerm_resource_group.rg.location
  private_link_resource_id     = azurerm_monitor_workspace.amw.id
  group_ids                    = ["prometheusMetrics"]
  private_link_resource_region = data.azurerm_resource_group.rg.location
}

resource "azurerm_dashboard_grafana_managed_private_endpoint" "ampls" {
  grafana_id                   = azurerm_dashboard_grafana.grafana.id
  name                         = "mpe-${var.monitor_private_link_scope_name}"
  location                     = data.azurerm_resource_group.rg.location
  private_link_resource_id     = azurerm_monitor_private_link_scope.ampls.id
  group_ids                    = ["azuremonitor"]
  private_link_resource_region = data.azurerm_resource_group.rg.location
}

# resource "azapi_update_resource" "grafana_managed_private_endpoint_connection_approval" {
#   type      = "Microsoft.Monitor/accounts/privateEndpointConnections@2023-04-03"
#   name      = "grafana-${var.grafana_dashboard_name}-${azurerm_dashboard_grafana_managed_private_endpoint.amw.name}"
#   parent_id = azurerm_monitor_workspace.amw.id

#   body = {
#     properties = {
#       privateLinkServiceConnectionState = {
#         actionsRequired = "None"
#         description     = "Approved via Terraform"
#         status          = "Approved"
#       }
#     }
#   }
# }

## Grafana role assignments
resource "azurerm_role_assignment" "datareaderrole" {
  scope                = azurerm_monitor_workspace.amw.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}

resource "azurerm_role_assignment" "ampls_datareaderrole" {
  scope                = azurerm_monitor_private_link_scope.ampls.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}

resource "azurerm_role_assignment" "grafana_admin" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_id
}


###################################
## Test Public Monitor & Grafana ##
###################################

resource "azurerm_monitor_workspace" "public_amw" {
  name                          = "public-amw"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  public_network_access_enabled = true
}

resource "azurerm_dashboard_grafana" "public_grafana" {
  name                          = "public-grafana"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  grafana_major_version         = 11
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.public_amw.id
  }
}

resource "azurerm_monitor_data_collection_endpoint" "public_dce_prometheus" {
  name                          = "public-dce-aks-01"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  kind                          = "Linux"
  public_network_access_enabled = true
}

resource "azurerm_role_assignment" "public_grafana_admin" {
  scope                = azurerm_dashboard_grafana.public_grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_id
}

resource "azurerm_role_assignment" "public_datareaderrole" {
  scope                = azurerm_monitor_workspace.public_amw.id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_dashboard_grafana.public_grafana.identity.0.principal_id
}

resource "azurerm_log_analytics_workspace" "public_log" {
  name                = "public-log"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
