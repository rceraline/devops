variable "vm_password" {
  sensitive   = true
  type        = string
  description = "Password of the virtual machine account."
}
