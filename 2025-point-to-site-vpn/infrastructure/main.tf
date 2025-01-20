resource "azurerm_resource_group" "vpn" {
  name     = "rg-vpn-01"
  location = "Canada Central"
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-01"
  location            = azurerm_resource_group.vpn.location
  resource_group_name = azurerm_resource_group.vpn.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vpn.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

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
    vpn_client_protocols = ["SSTP", "IkeV2"]

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
