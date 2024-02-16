resource "azurerm_container_registry" "cr" {
  name                          = "cr20240207"
  resource_group_name           = data.azurerm_resource_group.rg_01.name
  location                      = data.azurerm_resource_group.rg_01.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "cr" {
  name                = "pe-cr20240207"
  location            = data.azurerm_resource_group.rg_01.location
  resource_group_name = data.azurerm_resource_group.rg_01.name
  subnet_id           = data.azurerm_subnet.utils_01.id

  private_service_connection {
    name                           = "psc-cr20240207"
    private_connection_resource_id = azurerm_container_registry.cr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "pdzg-cr20240207"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.cr.id]
  }
}

data "azurerm_private_dns_zone" "cr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.rg_01.name
}
