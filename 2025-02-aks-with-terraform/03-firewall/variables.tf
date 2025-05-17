variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "pip_name" {
  type        = string
  description = "Name of the firewall public IP."
}

variable "firewall_name" {
  type        = string
  description = "Name of the firewall."
}

variable "firewall_subnet_name" {
  type        = string
  description = "Name of the firewall subnet."
}

variable "hub_vnet_name" {
  type        = string
  description = "Name of the Hub VNET."
}

variable "to_firewall_route_tables" {
  type = map(object({
    route_name     = string
    address_prefix = string
    vnet_name      = string
    subnet_name    = string
  }))
}
