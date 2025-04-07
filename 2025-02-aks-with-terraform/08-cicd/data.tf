data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "cicd" {
  name                = var.cicd_vnet_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "cicd_agents" {
  name                 = var.cicd_agent_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.cicd_vnet_name
}

data "azuread_service_principal" "devops_infrastructure" {
  display_name = "DevOpsInfrastructure" # This is a special built in service principal (see: https://learn.microsoft.com/en-us/azure/devops/managed-devops-pools/configure-networking?view=azure-devops&tabs=azure-portal#to-check-the-devopsinfrastructure-principal-access)
}
