variable "key_vault_crypto_officer_id" {
  type        = string
  description = "ID of the user who need Key Vault Certificates Officer role on the key vault."
}

variable "vm_password" {
  sensitive   = true
  type        = string
  description = "Password of the virtual machine account."
}
