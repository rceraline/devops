resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "hub_01" {
  name                = var.hub_vnet.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.hub_vnet.address_space

  dynamic "subnet" {
    for_each = var.hub_vnet.subnets

    content {
      name             = subnet.key
      address_prefixes = subnet.value.address_prefixes

      dynamic "delegation" {
        for_each = subnet.value.delegation == null ? [] : [subnet.value.delegation]

        content {
          name = delegation.value.name
          service_delegation {
            actions = delegation.value.service_delegation.actions
            name    = delegation.value.service_delegation.name
          }
        }
      }
    }
  }
}

resource "azurerm_virtual_network" "spokes" {
  for_each = var.spoke_vnets

  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = each.value.address_space

  dynamic "subnet" {
    for_each = each.value.subnets

    content {
      name             = subnet.key
      address_prefixes = subnet.value.address_prefixes
    }
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_vnets

  name                      = "peer-hub-01-to-${each.key}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub_01.name
  remote_virtual_network_id = azurerm_virtual_network.spokes[each.key].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_vnets

  name                      = "peer-${each.key}-to-hub-01"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spokes[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub_01.id
  allow_forwarded_traffic   = true
}
