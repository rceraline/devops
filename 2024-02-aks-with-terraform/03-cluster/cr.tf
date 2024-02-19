data "azurerm_container_registry" "cr" {
  name                = "cr20240207"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}
