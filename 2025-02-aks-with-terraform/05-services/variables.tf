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

variable "key_vault_name" {
  type        = string
  description = "Name of the key vault."
}

variable "container_registry_name" {
  type        = string
  description = "Namme of the container registry."
}
