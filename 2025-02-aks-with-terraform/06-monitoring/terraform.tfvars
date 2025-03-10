pe_subnet = {
  name      = "snet-pe-01"
  vnet_name = "vnet-aks-01"
}

resource_group_name = "rg-aks-with-terraform-01"

grafana_admin_id       = "b230bb12-c226-4606-a8ac-9ca05f2fbf66"
grafana_dashboard_name = "amg-01"

log_analytics_workspace_name             = "log-01"
monitor_private_link_scope_name          = "ampls-01"
monitor_private_link_scoped_service_name = "amplss-log-01"
monitor_workspace_name                   = "amw-01"
