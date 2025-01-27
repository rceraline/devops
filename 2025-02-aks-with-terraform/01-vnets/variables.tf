variable "hub_vnet" {
  type = object({
    name          = string
    address_space = set(string)
    subnets = map(object({
      address_prefixes = set(string)
      delegation = optional(object({
        name = string
        service_delegation = object({
          actions = set(string)
          name    = string
        })
      }))
    }))
  })
  description = "Hub virtual network information."
}

variable "location" {
  type        = string
  description = "The Azure location where to deploy the resources."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "spoke_vnets" {
  type = map(object({
    address_space = set(string)
    subnets = map(object({
      address_prefixes = set(string)
    }))
  }))
  description = "List of spoke virtual networks."
}
