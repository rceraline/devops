
resource "azurerm_resource_group" "rg" {
  name     = "rg-flux-01"
  location = "Canada Central"
}

## Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-flux-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

## ACR
resource "azurerm_container_registry" "cr" {
  name                = "cr20240706"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

## Identities
resource "azurerm_user_assigned_identity" "controlplane" {
  location            = azurerm_resource_group.rg.location
  name                = "id-flux-controlplane-01"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "kubelet" {
  location            = azurerm_resource_group.rg.location
  name                = "id-flux-kubelet-01"
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

resource "azurerm_role_assignment" "kubelet_acrpull" {
  scope                = azurerm_container_registry.cr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}

resource "azurerm_role_assignment" "cluster_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                   = "aks-flux-01"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  dns_prefix             = "aks-flux-01"
  kubernetes_version     = "1.28"
  local_account_disabled = true
  sku_tier               = "Standard"
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

  depends_on = [
    azurerm_role_assignment.controlplane_identity_contributor,
    azurerm_role_assignment.controlplane_resourcegroup_contributor
  ]
}

## Flux
resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = "flux-extension"
  cluster_id     = azurerm_kubernetes_cluster.aks.id
  extension_type = "microsoft.flux"
}

resource "azurerm_kubernetes_flux_configuration" "flux" {
  name       = "cluster-config"
  cluster_id = azurerm_kubernetes_cluster.aks.id
  namespace  = "cluster-config"
  scope      = "cluster"

  git_repository {
    url             = "https://github.com/Azure/gitops-flux2-kustomize-helm-mt"
    reference_type  = "branch"
    reference_value = "main"
  }

  kustomizations {
    name                       = "infra"
    path                       = "./infrastructure"
    garbage_collection_enabled = true
  }

  kustomizations {
    name                       = "apps"
    path                       = "./apps/staging"
    garbage_collection_enabled = true
    depends_on                 = ["infra"]
  }

  depends_on = [
    azurerm_kubernetes_cluster_extension.flux
  ]
}
