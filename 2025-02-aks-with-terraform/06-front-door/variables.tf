variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "aks_load_balancer_name" {
  type        = string
  description = "Name of the AKS private load balancer."
}

variable "load_balancer_subnet_name" {
  type        = string
  description = "Name of the load balancer subnet."
}

variable "aks_virtual_network_name" {
  type        = string
  description = "Name of the AKS VNET."
}
