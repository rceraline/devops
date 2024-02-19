resource "azurerm_user_assigned_identity" "controlplane" {
  location            = data.azurerm_resource_group.rg_01.location
  name                = "id-controlplane-01"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}

resource "azurerm_user_assigned_identity" "kubelet" {
  location            = data.azurerm_resource_group.rg_01.location
  name                = "id-kubelet-01"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}

resource "azurerm_role_assignment" "controlplane_identity_contributor" {
  scope                = azurerm_user_assigned_identity.kubelet.id
  role_definition_name = "Managed Identity Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "controlplane_resourcegroup_contributor" {
  scope                = data.azurerm_resource_group.rg_01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "controlplane_keyvault_crypto_user" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "kubelet_acrpull" {
  scope                = data.azurerm_container_registry.cr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

resource "azurerm_role_assignment" "agic" {
  scope                = data.azurerm_resource_group.rg_01.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks-01.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "azurerm_kubernetes_cluster" "aks-01" {
  name                       = "aks-01"
  location                   = data.azurerm_resource_group.rg_01.location
  resource_group_name        = data.azurerm_resource_group.rg_01.name
  private_cluster_enabled    = true
  dns_prefix_private_cluster = "aks-01"
  kubernetes_version         = "1.28"
  private_dns_zone_id        = data.azurerm_private_dns_zone.aks.id
  local_account_disabled     = true
  sku_tier                   = "Standard"

  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = data.azurerm_subnet.aks_01.id
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
    dns_service_ip = "10.1.3.4"
    service_cidr   = "10.1.3.0/24"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.agw_01.id
  }

  key_management_service {
    key_vault_key_id         = azurerm_key_vault_key.kms.id
    key_vault_network_access = "Private"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.cluster_admin_ids
    azure_rbac_enabled     = true
  }

  depends_on = [
    azurerm_role_assignment.controlplane_identity_contributor,
    azurerm_role_assignment.controlplane_keyvault_crypto_user,
    azurerm_role_assignment.controlplane_resourcegroup_contributor
  ]
}
