
resource "azurerm_federated_identity_credential" "fid" {
  name                = "fid-csi-driver-workloadidentity-01"
  resource_group_name = data.azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = data.azurerm_user_assigned_identity.workload_identity.id
  subject             = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
}
