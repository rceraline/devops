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
    subnets = {
      "snet-lb-01" = {
        address_prefixes = ["10.1.0.0/24"]
      }
      "snet-pe-01" = {
        address_prefixes = ["10.1.1.0/24"]
      }
      "snet-nodes-01" = {
        address_prefixes = ["10.1.2.0/24"]
      }
    }
  }
  "vnet-cicd-01" = {
    address_space = ["10.2.0.0/16"]
    subnets = {
      "snet-agent-01" = {
        address_prefixes = ["10.2.0.0/24"]
      }
    }
  }
}
