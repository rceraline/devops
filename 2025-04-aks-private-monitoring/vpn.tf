locals {
  dns_subnet_name             = "snet-dnsinbound-01"
  dns_subnet_address_prefixes = ["10.0.101.0/24"]
  private_dns_resolver_name   = "dnspr-01"
  dns_inbound_endpoint_name   = "dnsinbound-endpoint-01"

  vpn_subnet_name             = "GatewaySubnet"
  vpn_subnet_address_prefixes = ["10.0.100.0/24"]
  vpn_pip_name                = "pip-vpn-01"
  vpn_gateway_name            = "vgw-vpn-01"
  vpn_client_address_space    = ["10.200.0.0/24"]
  vpn_public_cert_data        = <<EOF
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

resource "azurerm_subnet" "gateway" {
  name                 = local.vpn_subnet_name
  address_prefixes     = local.vpn_subnet_address_prefixes
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_public_ip" "vpn" {
  name                = local.vpn_pip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = local.vpn_gateway_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  vpn_client_configuration {
    address_space        = local.vpn_client_address_space
    vpn_client_protocols = ["OpenVPN"]

    root_certificate {
      name = "VpnRoot"

      public_cert_data = local.vpn_public_cert_data
    }
  }
}

## DNS
resource "azurerm_subnet" "dns_inbound" {
  name                 = local.dns_subnet_name
  address_prefixes     = local.dns_subnet_address_prefixes
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_private_dns_resolver" "dnspr" {
  name                = local.private_dns_resolver_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  virtual_network_id  = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound" {
  name                    = local.dns_inbound_endpoint_name
  private_dns_resolver_id = azurerm_private_dns_resolver.dnspr.id
  location                = azurerm_private_dns_resolver.dnspr.location

  ip_configurations {
    subnet_id = azurerm_subnet.dns_inbound.id
  }
}
