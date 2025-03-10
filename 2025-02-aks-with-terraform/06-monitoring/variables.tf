variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "grafana_dashboard_name" {
  type        = string
  description = "Name of the grafana dashboard."
}

variable "pe_subnet" {
  type = object({
    name      = string
    vnet_name = string
  })
  description = "Subnet where the private service endpoints are deployed."
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the log analytics workspace."
}

variable "monitor_private_link_scope_name" {
  type        = string
  description = "Name of the monitor private link scope."
}

variable "monitor_private_link_scoped_service_name" {
  type        = string
  description = "Name of the monitor private link scoped service."
}

variable "monitor_workspace_name" {
  type        = string
  description = "Name of the monitor workspace."
}
