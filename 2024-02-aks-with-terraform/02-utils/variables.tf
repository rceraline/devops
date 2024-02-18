variable "key_vault_certificate_officer_id" {
  type        = string
  description = "ID of the user who need to manage certificates."
}

variable "vm_password" {
  sensitive   = true
  type        = string
  description = "Password of the virtual machine account."
}
