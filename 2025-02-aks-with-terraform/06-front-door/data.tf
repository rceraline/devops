data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_lb" "aks" {
  name                = var.aks_load_balancer_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "load_balancer" {
  name                 = var.load_balancer_subnet_name
  virtual_network_name = var.aks_virtual_network_name
  resource_group_name  = var.resource_group_name
}
