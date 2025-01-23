resource "azurerm_resource_group" "vpn" {
  name     = "rg-vpn-01"
  location = "Canada Central"
}

## VNET & Subnets
resource "azurerm_virtual_network" "vpn" {
  name                = "vnet-vpn-01"
  location            = azurerm_resource_group.vpn.location
  resource_group_name = azurerm_resource_group.vpn.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vpn.name
  virtual_network_name = azurerm_virtual_network.vpn.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "vpn_01" {
  name                 = "sub-vpn-01"
  resource_group_name  = azurerm_resource_group.vpn.name
  virtual_network_name = azurerm_virtual_network.vpn.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "inbound_dns" {
  name                 = "sub-inbounddns"
  resource_group_name  = azurerm_resource_group.vpn.name
  virtual_network_name = azurerm_virtual_network.vpn.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

## VPN
resource "azurerm_public_ip" "vpn_01" {
  name                = "pip-vpn-01"
  location            = azurerm_resource_group.vpn.location
  resource_group_name = azurerm_resource_group.vpn.name
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "vpn_01" {
  name                = "vgw-vpn-01"
  location            = azurerm_resource_group.vpn.location
  resource_group_name = azurerm_resource_group.vpn.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_01.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  vpn_client_configuration {
    address_space        = ["10.100.0.0/24"]
    vpn_client_protocols = ["OpenVPN"]

    root_certificate {
      name = "VpnRoot"

      public_cert_data = <<EOF
MIIC9TCCAd2gAwIBAgIQHAzVMIc/aY5JxYQjgH0iXTANBgkqhkiG9w0BAQsFADAd
MRswGQYDVQQDDBJWcG5Sb290Q2VydGlmaWNhdGUwHhcNMjUwMTIwMjExNDE4WhcN
MjYwMTIwMjEzNDE4WjAdMRswGQYDVQQDDBJWcG5Sb290Q2VydGlmaWNhdGUwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC62jOML+5NCw7O+U6PMc/zNMDV
5F+7qaJK08SnKy4iiD1rPq8TI5HGXJg+6wrhmgFYTLLzY8VpRhfJblrXNs5vgc2m
v+H9LjFBRc0QtMI8+2j+gmpYiaaQk3KNESP1JNvz6uOvPhAjwjCWE7wzJzUiBzL+
JShAhwG6e2DKYt8zyYWsy51Myeqx7hMCqTb/NZRSxKKUTqC4qU/NlGW+7oIkbsl1
2YZ0stgWnxx21uK6flG29C6sxfDPyENoRiCrw8t+YH0iJPKm9i98GM6qu/gALA2G
6wRtKGjFf5ZDpDMycUO6LekggF+h8Ry/PAOILFypTQpfZ6ybHXukHh2SdVh9AgMB
AAGjMTAvMA4GA1UdDwEB/wQEAwICBDAdBgNVHQ4EFgQUlfJPhTGCjK4x3q4iAi0Y
naKJNMowDQYJKoZIhvcNAQELBQADggEBAJyjEwGTzv0/6+UtesgPg0G+YIvgP7vj
ZMKANqeaypTdru3acsTcChJCmjtSA7ufBlZOhIwCWnzxY5b8Ugiuqnqv7oPWkr1u
Wl937ZLR+lHhywVQRGBzGKOo7JFlB/SiGr4F90Oq6fgZvBU0DlwPb8jo//t576R/
pt+616/9TcmWNu5Hoptb208e5x8sjMpCzalimxFx6xicSzJ2IDwEW5aaVKwJGho/
x4EkA6x5CAmBNbzSM4Xcptijkc125DNPzD8tn1PGgqu4xknNCW8XNbDhyi9WGsV8
t2XTIPZtX8fjUMlxxt72/FWRdm7ErQnz186/P+5zwAcIqvQjBSDfyzs=
EOF
    }
  }
}

## Storage Account
resource "azurerm_storage_account" "vpn" {
  name                          = "stvpn20250120"
  resource_group_name           = azurerm_resource_group.vpn.name
  location                      = azurerm_resource_group.vpn.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "storage_vpn" {
  name                = "pe-stvpn20250120"
  location            = azurerm_resource_group.vpn.location
  resource_group_name = azurerm_resource_group.vpn.name
  subnet_id           = azurerm_subnet.vpn_01.id

  private_service_connection {
    name                           = "psc-stvpn20250120"
    private_connection_resource_id = azurerm_storage_account.vpn.id
    is_manual_connection           = false
    subresource_names              = ["Blob"]
  }

  private_dns_zone_group {
    name                 = "pdzg-stvpn20250120"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

## Private DNS Zone
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.vpn.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "link-hub"
  resource_group_name   = azurerm_resource_group.vpn.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.vpn.id
}

##Dns Private Resolver
resource "azurerm_private_dns_resolver" "vpn" {
  name                = "dnspr-vpn-01"
  resource_group_name = azurerm_resource_group.vpn.name
  location            = azurerm_resource_group.vpn.location
  virtual_network_id  = azurerm_virtual_network.vpn.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound" {
  name                    = "in-vpn-01"
  private_dns_resolver_id = azurerm_private_dns_resolver.vpn.id
  location                = azurerm_private_dns_resolver.vpn.location

  ip_configurations {
    subnet_id = azurerm_subnet.inbound_dns.id
  }
}
