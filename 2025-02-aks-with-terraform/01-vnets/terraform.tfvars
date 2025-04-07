location            = "Canada Central"
resource_group_name = "rg-aks-with-terraform-01"

hub_vnet = {
  name          = "vnet-hub-01"
  address_space = ["10.0.0.0/16"]
  subnets = {
    "GatewaySubnet" = {
      address_prefixes = ["10.0.0.0/24"]
    }
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "snet-dnsinbound-01" = {
      address_prefixes = ["10.0.2.0/24"]
      delegation = {
        name = "Microsoft.Network.dnsResolvers"
        service_delegation = {
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          name    = "Microsoft.Network/dnsResolvers"
        }
      }
    }
  }
}

spoke_vnets = {
  "vnet-aks-01" = {
    address_space = ["10.1.0.0/16"]
  }
  "vnet-cicd-01" = {
    address_space = ["10.2.0.0/16"]
  }
}

spoke_vnet_subnets = [
  {
    name             = "snet-lb-01"
    vnet_name        = "vnet-aks-01"
    address_prefixes = ["10.1.0.0/24"]
  },
  {
    name             = "snet-pe-01"
    vnet_name        = "vnet-aks-01"
    address_prefixes = ["10.1.1.0/24"]
  },
  {
    name             = "snet-nodes-01"
    vnet_name        = "vnet-aks-01"
    address_prefixes = ["10.1.2.0/24"]
  },

  {
    name             = "snet-agent-01"
    vnet_name        = "vnet-cicd-01"
    address_prefixes = ["10.2.0.0/24"]
    delegation = {
      name = "Microsoft.DevOpsInfrastructure/pools"
      service_delegation = {
        name = "Microsoft.DevOpsInfrastructure/pools"
      }
    }
  }
]

vpn_client_address_space = ["10.100.0.0/24"]
vpn_gateway_name         = "vgw-vpn-01"
vpn_pip_name             = "pip-vpn-01"
vpn_public_cert_data     = <<EOF
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
