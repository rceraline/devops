resource "azurerm_public_ip" "pip" {
  name                = var.pip_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "afw" {
  name                = var.firewall_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = data.azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "allow_all" {
  name                = "allow-all-nr"
  azure_firewall_name = azurerm_firewall.afw.name
  resource_group_name = data.azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "All"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "Any",
    ]
  }
}

## Route Tables
resource "azurerm_route_table" "rts" {
  for_each = var.to_firewall_route_tables

  name                = each.key
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  route {
    name                   = each.value.route_name
    address_prefix         = each.value.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.afw.ip_configuration.0.private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "route_associations" {
  for_each = var.to_firewall_route_tables

  subnet_id      = "${data.azurerm_subscription.current.id}/resourceGroups/${data.azurerm_resource_group.rg.name}/providers/Microsoft.Network/virtualNetworks/${each.value.vnet_name}/subnets/${each.value.subnet_id}"
  route_table_id = azurerm_route_table.rts[each.key].id
}
