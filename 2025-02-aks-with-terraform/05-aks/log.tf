resource "azurerm_log_analytics_workspace" "log" {
  name                = var.log_analytics_workspace_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_private_link_scoped_service" "log" {
  name                = "log-${var.monitor_private_link_scope_name}"
  resource_group_name = data.azurerm_resource_group.rg.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = azurerm_log_analytics_workspace.log.id
}

resource "azurerm_monitor_data_collection_rule" "dcr_container_insights" {
  name                = "MSCI--${azurerm_kubernetes_cluster.aks.name}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.log.id
      name                  = "ciworkspace"
    }
  }

  data_flow {
    streams      = var.streams
    destinations = ["ciworkspace"]
  }

  data_sources {
    extension {
      streams        = var.streams
      extension_name = "ContainerInsights"
      extension_json = jsonencode({
        "dataCollectionSettings" : {
          "interval" : var.data_collection_interval,
          "namespaceFilteringMode" : var.namespace_filtering_mode_for_data_collection,
          "namespaces" : var.namespaces_for_data_collection
          "enableContainerLogV2" : var.enableContainerLogV2
        }
      })
      name = "ContainerInsightsExtension"
    }
  }

  description = "DCR for Azure Monitor Container Insights"
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_container_insights" {
  name                    = "ContainerInsightsExtension"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr_container_insights.id
  description             = "Association of container insights data collection rule. Deleting this association will break the data collection for this AKS Cluster."
}
