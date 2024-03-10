variable "cluster_admin_ids" {
  type        = list(string)
  description = "List of cluster admin IDs."
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
