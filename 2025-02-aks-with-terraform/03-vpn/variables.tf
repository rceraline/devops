variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "hub_vnet_name" {
  type        = string
  description = "Name of the Hub virtual network."
}

variable "gateway_subnet_name" {
  type        = string
  description = "Name of the Gateway subnet."
}

variable "vpn_pip_name" {
  type        = string
  description = "Name of the VPN public IP."
}

variable "vpn_gateway_name" {
  type        = string
  description = "Name of the VPN gateway."
}

variable "vpn_client_address_space" {
  type        = list(string)
  description = "List of VPN client address spaces."
}

variable "vpn_public_cert_data" {
  type        = string
  description = "Public root certificate in base64."
}
