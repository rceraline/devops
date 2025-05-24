locals {
  aks_name             = "aks-addon-01"
  key_vault_name       = "kv20250524"
  resource_group_name  = "rg-aks-addon-01"
  custom_dns_zone_name = "sometestcustomdomain.com"
  aks_dns_zone         = "privatelink.canadacentral.azmk8s.io"
  vnet_name            = "vnet-01"
  subnet_name          = "snet-01"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = "Canada Central"
}

## Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "administrator" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

## Identities
resource "azurerm_user_assigned_identity" "controlplane" {
  location            = azurerm_resource_group.rg.location
  name                = "id-controlplane-01"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "controlplane_resourcegroup_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
}

resource "azurerm_role_assignment" "web_app_routing_private_dns_zone" {
  scope                = azurerm_dns_zone.domain.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.web_app_routing[0].web_app_routing_identity[0].object_id
}

resource "azurerm_role_assignment" "web_app_routing_key_vault_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.web_app_routing[0].web_app_routing_identity[0].object_id
}

## Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = local.aks_name
  sku_tier            = "Standard"

  default_node_pool {
    name       = "system"
    node_count = 3
    vm_size    = "Standard_D2s_v3"

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

  network_profile {
    network_plugin = "kubenet"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  web_app_routing {
    dns_zone_ids = [azurerm_dns_zone.domain.id]
  }

  depends_on = [azurerm_role_assignment.controlplane_resourcegroup_contributor]
}

## DNS
resource "azurerm_dns_zone" "domain" {
  name                = local.custom_dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}
