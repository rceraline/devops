resource_group_name                   = "rg-aks-with-terraform-01"
container_registry_name               = "cr20250201"
aks_name                              = "aks-01"
aks_version                           = "1.31"
aks_nodes_subnet_name                 = "snet-nodes-01"
aks_vnet_name                         = "vnet-aks-01"
cluster_admin_ids                     = ["b230bb12-c226-4606-a8ac-9ca05f2fbf66"]
key_vault_name                        = "kv-20250201"
log_analytics_workspace_name          = "public-log"
grafana_dashboard_name                = "grafana-01"
grafana_version                       = "10"
monitor_data_collection_endpoint_name = "dce-aks-01"
monitor_data_collection_rule_name     = "dcr-01"
monitor_workspace_name                = "new-amw-01"
monitor_private_link_scope_name       = "ampls-01"

pe_subnet = {
  name      = "snet-pe-01"
  vnet_name = "vnet-aks-01"
}
