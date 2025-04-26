resource "azurerm_dev_center" "dev_center" {
  name                = var.dev_center_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_dev_center_project" "project" {
  dev_center_id       = azurerm_dev_center.dev_center.id
  name                = var.dev_center_project_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "reader" {
  scope                = data.azurerm_virtual_network.cicd.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_service_principal.devops_infrastructure.object_id
}

resource "azurerm_role_assignment" "network_contributor" {
  scope                = data.azurerm_virtual_network.cicd.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azuread_service_principal.devops_infrastructure.object_id
}

module "managed_devops_pool" {
  source = "Azure/avm-res-devopsinfrastructure-pool/azurerm"

  resource_group_name                      = data.azurerm_resource_group.rg.name
  location                                 = data.azurerm_resource_group.rg.location
  name                                     = var.managed_devops_pool_name
  dev_center_project_resource_id           = azurerm_dev_center_project.project.id
  version_control_system_organization_name = var.version_control_system_organization_name
  version_control_system_project_names     = var.version_control_system_project_names
  subnet_id                                = data.azurerm_subnet.cicd_agents.id

  depends_on = [
    azurerm_role_assignment.reader,
    azurerm_role_assignment.network_contributor
  ]
}
