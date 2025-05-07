resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.hub_vnet.address_space
}

resource "azurerm_subnet" "hub_subnets" {
  for_each = var.hub_vnet.subnets

  name                 = each.key
  address_prefixes     = each.value.address_prefixes
  virtual_network_name = azurerm_virtual_network.hub.name
  resource_group_name  = azurerm_virtual_network.hub.resource_group_name

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]

    content {
      name = delegation.value.name
      service_delegation {
        actions = delegation.value.service_delegation.actions
        name    = delegation.value.service_delegation.name
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
}

resource "azurerm_subnet" "spoke_subnets" {
  for_each = {
    for vnet_subnet in var.spoke_vnet_subnets :
    "${vnet_subnet.vnet_name}_${vnet_subnet.name}" => vnet_subnet
  }

  name                                          = each.value.name
  address_prefixes                              = each.value.address_prefixes
  virtual_network_name                          = each.value.vnet_name
  resource_group_name                           = azurerm_resource_group.rg.name
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]

    content {
      name = delegation.value.name
      service_delegation {
        actions = delegation.value.service_delegation.actions
        name    = delegation.value.service_delegation.name
      }
    }
  }

  depends_on = [azurerm_virtual_network.spokes]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_vnets

  name                      = "peer-hub-01-to-${each.key}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spokes[each.key].id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_vnets

  name                      = "peer-${each.key}-to-hub-01"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spokes[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true

  depends_on = [azurerm_virtual_network_gateway.vpn]
}

resource "azurerm_public_ip" "vpn" {
  name                = var.vpn_pip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = var.vpn_gateway_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub_subnets["GatewaySubnet"].id
  }

  vpn_client_configuration {
    address_space        = var.vpn_client_address_space
    vpn_client_protocols = ["OpenVPN"]

    root_certificate {
      name = "VpnRoot"

      public_cert_data = var.vpn_public_cert_data
    }
  }
}
