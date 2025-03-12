variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "container_registry_name" {
  type        = string
  description = "Name of the container registry."
}

variable "aks_name" {
  type        = string
  description = "Name of the Kubernetes cluster."
}

variable "aks_version" {
  type        = string
  description = "Version of the Kubernetes cluster."
}

variable "aks_nodes_subnet_name" {
  type        = string
  description = "Name of the subnet where to deploy the Kubernetes cluster nodes."
}

variable "aks_vnet_name" {
  type        = string
  description = "Name of the virtual network where to deploy the Kubernetes cluster."
}

variable "cluster_admin_ids" {
  type        = list(string)
  description = "List of user or group IDs that will be admin of the cluster."
}

variable "grafana_dashboard_name" {
  type        = string
  description = "Name of the Grafana dashboard."
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the log analytics workspace."
}

variable "key_vault_name" {
  type        = string
  description = "Name of the key vault."
}

variable "monitor_workspace_name" {
  type        = string
  description = "Name of the Azure Monitor Workspace."
}
