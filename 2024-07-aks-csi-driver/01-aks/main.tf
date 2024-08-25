### Resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-csi-driver-01"
  location = "Canada Central"
}

### Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-csi-driver-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

### Key vault
resource "azurerm_key_vault" "kv" {
  name                        = "kv-2024070102"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  enable_rbac_authorization = true
}

### Identities
resource "azurerm_user_assigned_identity" "controlplane" {
  location            = azurerm_resource_group.rg.location
  name                = "id-csi-driver-controlplane-01"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "kubelet" {
  location            = azurerm_resource_group.rg.location
  name                = "id-csi-driver-kubelet-01"
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

resource "azurerm_role_assignment" "cluster_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

### CSI Driver identity
resource "azurerm_user_assigned_identity" "workload_identity" {
  location            = azurerm_resource_group.rg.location
  name                = "id-csi-driver-workloadidentity-01"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "secret_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
}

### AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                   = "aks-csi-driver-01"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  dns_prefix             = "aks-csi-driver-01"
  kubernetes_version     = "1.30"
  local_account_disabled = true
  sku_tier               = "Free"
  oidc_issuer_enabled    = true

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks.id
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

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  depends_on = [
    azurerm_role_assignment.controlplane_identity_contributor,
    azurerm_role_assignment.controlplane_resourcegroup_contributor
  ]
}
