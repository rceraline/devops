# ## Identities
# resource "azurerm_user_assigned_identity" "controlplane" {
#   location            = data.azurerm_resource_group.rg.location
#   name                = "id-controlplane-01"
#   resource_group_name = data.azurerm_resource_group.rg.name
# }

# resource "azurerm_user_assigned_identity" "kubelet" {
#   location            = data.azurerm_resource_group.rg.location
#   name                = "id-kubelet-01"
#   resource_group_name = data.azurerm_resource_group.rg.name
# }

# resource "azurerm_role_assignment" "controlplane_identity_contributor" {
#   scope                = azurerm_user_assigned_identity.kubelet.id
#   role_definition_name = "Managed Identity Contributor"
#   principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
# }

# resource "azurerm_role_assignment" "controlplane_resourcegroup_contributor" {
#   scope                = data.azurerm_resource_group.rg.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
# }

# resource "azurerm_role_assignment" "controlplane_keyvault_crypto_user" {
#   scope                = data.azurerm_key_vault.kv.id
#   role_definition_name = "Key Vault Crypto User"
#   principal_id         = azurerm_user_assigned_identity.controlplane.principal_id
# }

# resource "azurerm_role_assignment" "kubelet_acrpull" {
#   scope                = data.azurerm_container_registry.cr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
# }

# resource "azurerm_role_assignment" "cluster_admins" {
#   for_each = toset(var.cluster_admin_ids)

#   scope                = azurerm_kubernetes_cluster.aks.id
#   role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
#   principal_id         = each.key
# }

# resource "azurerm_role_assignment" "web_app_routing_private_dns_zone" {
#   scope                = data.azurerm_private_dns_zone.mydomain.id
#   role_definition_name = "Private DNS Zone Contributor"
#   principal_id         = azurerm_kubernetes_cluster.aks.web_app_routing[0].web_app_routing_identity[0].object_id
# }

## KMS key
# resource "azurerm_role_assignment" "crypto_officer" {
#   scope                = data.azurerm_key_vault.kv.id
#   role_definition_name = "Key Vault Crypto Officer"
#   principal_id         = data.azurerm_client_config.current.object_id
# }

# resource "azurerm_key_vault_key" "kms" {
#   name         = "generated-kms"
#   key_vault_id = data.azurerm_key_vault.kv.id
#   key_type     = "RSA"
#   key_size     = 2048

#   key_opts = [
#     "decrypt",
#     "encrypt"
#   ]

#   depends_on = [azurerm_role_assignment.crypto_officer]
# }

## AKS
# resource "azurerm_kubernetes_cluster" "aks" {
#   name                       = var.aks_name
#   location                   = data.azurerm_resource_group.rg.location
#   resource_group_name        = data.azurerm_resource_group.rg.name
#   private_cluster_enabled    = true
#   dns_prefix_private_cluster = var.aks_name
#   kubernetes_version         = var.aks_version
#   private_dns_zone_id        = data.azurerm_private_dns_zone.aks.id
#   # local_account_disabled     = true
#   sku_tier = "Standard"

#   default_node_pool {
#     name                         = "system"
#     node_count                   = 3
#     only_critical_addons_enabled = true
#     vm_size                      = "Standard_D2s_v3"
#     vnet_subnet_id               = data.azurerm_subnet.nodes.id
#     zones                        = ["1", "2", "3"]

#     upgrade_settings {
#       drain_timeout_in_minutes      = 0
#       max_surge                     = "10%"
#       node_soak_duration_in_minutes = 0
#     }
#   }

#   identity {
#     type         = "UserAssigned"
#     identity_ids = [azurerm_user_assigned_identity.controlplane.id]
#   }

#   kubelet_identity {
#     client_id                 = azurerm_user_assigned_identity.kubelet.client_id
#     object_id                 = azurerm_user_assigned_identity.kubelet.principal_id
#     user_assigned_identity_id = azurerm_user_assigned_identity.kubelet.id
#   }

#   network_profile {
#     network_plugin = "azure"
#     dns_service_ip = "10.1.3.4"
#     service_cidr   = "10.1.3.0/24"
#   }

#   # KMS cannot be enabled with Terraform until VNET integration is GA.
#   # key_management_service {
#   #   key_vault_key_id         = azurerm_key_vault_key.kms.id
#   #   key_vault_network_access = "Private"
#   # }

#   # azure_active_directory_role_based_access_control {
#   #   admin_group_object_ids = var.cluster_admin_ids
#   #   azure_rbac_enabled     = true
#   # }

#   monitor_metrics {
#     annotations_allowed = null
#     labels_allowed      = null
#   }

#   web_app_routing {
#     dns_zone_ids = [data.azurerm_private_dns_zone.mydomain.id]
#   }

#   depends_on = [
#     azurerm_role_assignment.controlplane_identity_contributor,
#     azurerm_role_assignment.controlplane_keyvault_crypto_user,
#     azurerm_role_assignment.controlplane_resourcegroup_contributor,
#   ]
# }

# ## user node pool
# resource "azurerm_kubernetes_cluster_node_pool" "user" {
#   name                  = "user"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
#   vm_size               = "Standard_D2s_v3"
#   auto_scaling_enabled  = true
#   max_count             = 10
#   min_count             = 2
#   vnet_subnet_id        = data.azurerm_subnet.nodes.id
#   zones                 = ["1", "2", "3"]
# }
