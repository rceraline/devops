locals {
  aks_name = "aks-01"
  all_private_dns_zone_names = [
    "privatelink.canadacentral.azmk8s.io",
    "privatelink.canadacentral.prometheus.monitor.azure.com",
    "privatelink.grafana.azure.com",
    "privatelink.blob.core.windows.net",        ## require for AMPLS
    "privatelink.monitor.azure.com",            ## require for AMPLS
    "privatelink.oms.opinsights.azure.com",     ## require for AMPLS
    "privatelink.ods.opinsights.azure.com",     ## require for AMPLS
    "privatelink.agentsvc.azure-automation.net" ## require for AMPLS
  ]
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-private-monitoring-01"
  location = "Canada Central"
}

## Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "snet_01" {
  name                 = "snet-01"
  address_prefixes     = ["10.0.0.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet_02" {
  name                 = "snet-02"
  address_prefixes     = ["10.0.2.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

## Dns
resource "azurerm_private_dns_zone" "zones" {
  for_each = toset(local.all_private_dns_zone_names)

  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "zone_links" {
  for_each = toset(local.all_private_dns_zone_names)

  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.vnet.id

  depends_on = [azurerm_private_dns_zone.zones]
}

## Identities
resource "azurerm_user_assigned_identity" "controlplane" {
  location            = azurerm_resource_group.rg.location
  name                = "id-controlplane-01"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "kubelet" {
  location            = azurerm_resource_group.rg.location
  name                = "id-kubelet-01"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "controlplane_identity_contributor" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "controlplane_resourcegroup_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

# AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                       = local.aks_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  private_cluster_enabled    = true
  dns_prefix_private_cluster = local.aks_name
  private_dns_zone_id        = azurerm_private_dns_zone.zones["privatelink.canadacentral.azmk8s.io"].id
  sku_tier                   = "Standard"

  default_node_pool {
    name           = "system"
    node_count     = 3
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.snet_01.id

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.controlplane.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
  }

  network_profile {
    network_plugin = "azure"
    dns_service_ip = "10.0.1.4"
    service_cidr   = "10.0.1.0/24"
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  depends_on = [
    azurerm_role_assignment.controlplane_identity_contributor,
    azurerm_role_assignment.controlplane_resourcegroup_contributor,
  ]
}
