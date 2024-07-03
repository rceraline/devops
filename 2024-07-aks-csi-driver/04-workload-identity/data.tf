data "azurerm_resource_group" "rg" {
  name = "rg-csi-driver-01"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-csi-driver-01"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_user_assigned_identity" "workload_identity" {
  name                = "id-csi-driver-workloadidentity-01"
  resource_group_name = data.azurerm_resource_group.rg.name
}
