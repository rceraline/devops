resource_group_name  = "rg-aks-with-terraform-01"
pip_name             = "pip-afw-01"
firewall_name        = "afw-01"
firewall_subnet_name = "AzureFirewallSubnet"
hub_vnet_name        = "vnet-hub-01"
to_firewall_route_tables = {
  "rt-agent-to-aks-01" = {
    route_name     = "route-to-aks"
    address_prefix = "10.1.0.0/16"
    vnet_name      = "vnet-cicd-01"
    subnet_name    = "snet-agent-01"
  }
  "rt-go-to-firewall-01" = {
    route_name     = "route-to-aks"
    address_prefix = "0.0.0.0/0"
    vnet_name      = "vnet-aks-01"
    subnet_name    = "snet-nodes-01"
  }
}
