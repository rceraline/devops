resource "azurerm_user_assigned_identity" "controlplane" {
  location            = data.azurerm_resource_group.rg.location
  name                = "id-csi-driver-controlplane-01"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "kubelet" {
  location            = data.azurerm_resource_group.rg.location
  name                = "id-csi-driver-kubelet-01"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "controlplane_identity_contributor" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "controlplane_resourcegroup_contributor" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "kubelet_acrpull" {
  scope                = data.azurerm_container_registry.cr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

resource "azurerm_role_assignment" "cluster_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-csi-driver-01"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aks-csi-driver-01"
  kubernetes_version  = "1.28"
  # private_dns_zone_id    = data.azurerm_private_dns_zone.aks.id
  local_account_disabled = true
  sku_tier               = "Standard"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = data.azurerm_subnet.aks.id
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
    network_plugin = "kubenet"
    dns_service_ip = "10.0.3.4"
    service_cidr   = "10.0.3.0/24"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.cluster_admin_ids
    azure_rbac_enabled     = true
  }

  depends_on = [
    azurerm_role_assignment.controlplane_identity_contributor,
    azurerm_role_assignment.controlplane_resourcegroup_contributor
  ]
}
