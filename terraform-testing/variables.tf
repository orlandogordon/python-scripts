variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID. Also used as the tenant-root management group ID."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID used by the provider for API calls."
}

variable "target_env" {
  type        = string
  description = "Environment folder under azure_policies/ to deploy (e.g. development, production)."
}

variable "policies_root" {
  type        = string
  default     = "azure_policies"
  description = "Root directory containing the <env>/rules/**/*.yml tree."
}
