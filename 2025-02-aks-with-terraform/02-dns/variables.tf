variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "dnsinbound_endpoint_ip_address" {
  type        = string
  description = "IP address of the DNS inbound endpoint."
}

variable "dnsinbound_endpoint_name" {
  type        = string
  description = "Name of the DNS inbound endpoint."
}

variable "dnsinbound_subnet_name" {
  type        = string
  description = "Name of the DNS inbound endpoint subnet."
}

variable "dns_resolver_name" {
  type        = string
  description = "Name of the DNS private resolver."
}

variable "hub_vnet_name" {
  type        = string
  description = "Name of the hub virtual network."
}

variable "private_dns_zone_names" {
  type        = set(string)
  description = "List of private dns zone names."
}

variable "all_vnet_names" {
  type        = set(string)
  description = "List of all virtual network names."
}
