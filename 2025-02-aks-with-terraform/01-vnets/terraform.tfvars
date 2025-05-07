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
    name                                          = "snet-lb-01"
    vnet_name                                     = "vnet-aks-01"
    address_prefixes                              = ["10.1.0.0/24"]
    private_link_service_network_policies_enabled = false
  },
  {
    name                                          = "snet-pe-01"
    vnet_name                                     = "vnet-aks-01"
    address_prefixes                              = ["10.1.1.0/24"]
    private_link_service_network_policies_enabled = true
  },
  {
    name                                          = "snet-nodes-01"
    vnet_name                                     = "vnet-aks-01"
    address_prefixes                              = ["10.1.2.0/24"]
    private_link_service_network_policies_enabled = true
  },

  {
    name                                          = "snet-agent-01"
    vnet_name                                     = "vnet-cicd-01"
    address_prefixes                              = ["10.2.0.0/24"]
    private_link_service_network_policies_enabled = true
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
MIIC9TCCAd2gAwIBAgIQFt6h/r2m5YxBCuImGVtfuDANBgkqhkiG9w0BAQsFADAd
MRswGQYDVQQDDBJWcG5Sb290Q2VydGlmaWNhdGUwHhcNMjUwNTA3MTYzMDUzWhcN
MjYwNTA3MTY1MDUzWjAdMRswGQYDVQQDDBJWcG5Sb290Q2VydGlmaWNhdGUwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC/mZXVvpWTACc3dTx4QtBdL/jE
GnSwOYklMAwopELmC98a7USNzLL7j8uukfTf0/mPEVOF1SKsfsFYsf71OS9kplb5
+Bw16XyA+2Mh/TGTlMyHBQAdJB0M97TXsXNvPZs929CHFhXAWSk/hCaphlwm1CNK
8xqoaUNyg4zfmtCjTlmQbF6Fe0QRJ7s4IkSkMLZRlipOPJzmD9Z+cSzzCIZO0aRn
MqkvWF45/xlFdm5lF7IfHbqv0zSeAtLBAktIZqM0TTBaF/3mxA0vYTNhTlQF6K/a
JzjFupQFbJMsWyRGUUIGLF46/T6GE9/Nv5l2BAZKLQSXXr9j10HtX7lePfpNAgMB
AAGjMTAvMA4GA1UdDwEB/wQEAwICBDAdBgNVHQ4EFgQUBbvqObyQ3avqUKBdcIUd
7pA1cg0wDQYJKoZIhvcNAQELBQADggEBABmGyErLNNzNy/39/BLuHgcK2FQdB2FT
wlW6810hVArzf1QSwMdSSSSbgqVEvvVCRPfjReG4IZEh66DMJKNf+otFE3eJB2Ys
OB3LprPTHooNVqu1+1Vd7Y7K3bBGQVYC8Ef+2ygbYIeaGZTme03gQu7ccXOy/rKG
pr0xD+gclDEWyje18ag7pRop6fBEA+2/pMCkjAngI4sUU8EGnvzLFhZVPNy9ruip
GnRWuuvarfcds347wj+96XhHejBC/jsjkcEw5EJIS9AhT5cg9l/7zvNiWjOWdaf0
EjAQQHK/wtk/nKfw0p8ClHeS1UNUwfkljP3oB66MVygJMpUoq6OJ6U8=
EOF
