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

variable "grafana_version" {
  type        = string
  description = "Version of Grafana."
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

variable "monitor_data_collection_endpoint_name" {
  type        = string
  description = "Name of the Azure monitor DCE."
}

variable "monitor_data_collection_rule_name" {
  type        = string
  description = "Name of the Azure monitor DCR."
}

variable "monitor_private_link_scope_name" {
  type        = string
  description = "Name of the Azure Monitor Private Link Scope."
}

variable "pe_subnet" {
  type = object({
    name      = string
    vnet_name = string
  })
  description = "Subnet where the private service endpoints are deployed."
}



variable "data_collection_interval" {
  default = "1m"
}

variable "namespace_filtering_mode_for_data_collection" {
  default = "Off"
}

variable "namespaces_for_data_collection" {
  default = ["kube-system", "gatekeeper-system", "azure-arc"]
}

variable "enableContainerLogV2" {
  default = true
}

variable "streams" {
  default = ["Microsoft-ContainerLog", "Microsoft-ContainerLogV2", "Microsoft-KubeEvents", "Microsoft-KubePodInventory", "Microsoft-KubeNodeInventory", "Microsoft-KubePVInventory", "Microsoft-KubeServices", "Microsoft-KubeMonAgentEvents", "Microsoft-InsightsMetrics", "Microsoft-ContainerInventory", "Microsoft-ContainerNodeInventory", "Microsoft-Perf"]
}
