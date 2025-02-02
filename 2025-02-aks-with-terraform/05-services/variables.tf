variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "pe_subnet" {
  type = object({
    name      = string
    vnet_name = string
  })
  description = "Subnet where the private service endpoints are deployed."
}
