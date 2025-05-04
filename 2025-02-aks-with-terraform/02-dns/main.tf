## DNS Private Resolver
resource "azurerm_private_dns_resolver" "dnspr" {
  name                = var.dns_resolver_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  virtual_network_id  = data.azurerm_virtual_network.hub.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound" {
  name                    = var.dnsinbound_endpoint_name
  private_dns_resolver_id = azurerm_private_dns_resolver.dnspr.id
  location                = azurerm_private_dns_resolver.dnspr.location

  ip_configurations {
    subnet_id          = data.azurerm_subnet.dnsinbound.id
    private_ip_address = var.dnsinbound_endpoint_ip_address
  }
}

## Private DNS Zones
resource "azurerm_private_dns_zone" "zones" {
  for_each = var.private_dns_zone_names

  name                = each.key
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "zone_links" {
  for_each = {
    for link in flatten([
      for vnet in var.all_vnet_names :
      [for zone in var.private_dns_zone_names : {
        vnet = vnet
        zone = zone
      }]
    ]) :
    "link-${link.vnet}-to-${link.zone}" => link
  }

  name                  = each.key
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = each.value.zone
  virtual_network_id    = data.azurerm_virtual_network.all_vnets[each.value.vnet].id

  depends_on = [azurerm_private_dns_zone.zones]
}
