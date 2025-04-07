variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "managed_devops_pool_name" {
  type        = string
  description = "Name of the Managed DevOps pool."
}

variable "dev_center_name" {
  type        = string
  description = "Name of the Dev center."
}

variable "dev_center_project_name" {
  type        = string
  description = "Name of the Dev center project."
}

variable "cicd_agent_subnet_name" {
  type        = string
  description = "Name of the agent subnet for cicd."
}

variable "cicd_vnet_name" {
  type        = string
  description = "Name of the cicd VNET."
}

variable "version_control_system_organization_name" {
  type        = string
  description = "Name of the Azure DevOps organization."
}

variable "version_control_system_project_names" {
  type        = list(string)
  description = "List of project names in Azure DevOps."
}
