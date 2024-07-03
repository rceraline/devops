variable "service_account_name" {
  type        = string
  description = "Name of the service account used for workload identity."
  default     = "workload-identity-sa"
}

variable "service_account_namespace" {
  type        = string
  description = "Name of the namespace where the service account is created."
  default     = "default"
}
