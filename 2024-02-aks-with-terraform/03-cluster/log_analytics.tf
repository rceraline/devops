resource "azurerm_log_analytics_workspace" "log" {
  name                = "log-01"
  location            = data.azurerm_resource_group.rg_01.location
  resource_group_name = data.azurerm_resource_group.rg_01.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
