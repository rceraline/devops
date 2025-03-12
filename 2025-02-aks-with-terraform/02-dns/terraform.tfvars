resource_group_name = "rg-aks-with-terraform-01"

dnsinbound_endpoint_name = "dnsinbound-endpoint-01"
dnsinbound_subnet_name   = "snet-dnsinbound-01"
dns_resolver_name        = "dnspr-01"

hub_vnet_name = "vnet-hub-01"
private_dns_zone_names = [
  "privatelink.azurecr.io",
  "privatelink.blob.core.windows.net",
  "privatelink.canadacentral.azmk8s.io",
  "privatelink.canadacentral.prometheus.monitor.azure.com",
  "privatelink.grafana.azure.com",
  "privatelink.monitor.azure.com",
  "privatelink.vaultcore.azure.net"
]
all_vnet_names = [
  "vnet-aks-01",
  "vnet-cicd-01",
  "vnet-hub-01"
]
