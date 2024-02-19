data "azurerm_key_vault" "kv" {
  name                = "kv-20240207"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}
