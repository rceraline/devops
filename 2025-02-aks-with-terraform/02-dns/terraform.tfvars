resource_group_name = "rg-aks-with-terraform-01"

dnsinbound_endpoint_name = "dnsinbound-endpoint-01"
dnsinbound_subnet_name   = "snet-dnsinbound-01"
dns_resolver_name        = "dnspr-01"

hub_vnet_name = "vnet-hub-01"
private_dns_zone_names = [
  "mydomain.com",
  "privatelink.azurecr.io",
  "privatelink.blob.core.windows.net", ## will be used by AMPLS too
  "privatelink.canadacentral.azmk8s.io",
  "privatelink.canadacentral.prometheus.monitor.azure.com",
  "privatelink.grafana.azure.com",
  "privatelink.vaultcore.azure.net",
  "privatelink.monitor.azure.com",            ## require for AMPLS
  "privatelink.oms.opinsights.azure.com",     ## require for AMPLS
  "privatelink.ods.opinsights.azure.com",     ## require for AMPLS
  "privatelink.agentsvc.azure-automation.net" ## require for AMPLS
]
all_vnet_names = [
  "vnet-aks-01",
  "vnet-cicd-01",
  "vnet-hub-01"
]
