variable "artifact_path" {
  type        = string
  description = "Absolute path to the artifact folder containing rules/, initiatives/, and assignments/."
}

variable "target_mg" {
  type        = string
  description = "Management group name (short name) used as the scope for all definitions, initiatives, and assignments in this artifact."
}

variable "enforce" {
  type        = bool
  default     = true
  description = "Whether assignments should be enforced (true) or audit-only (false)."
}



# modules/deployer/variables.tf

variable "artifact_name" {
  type = string
}

variable "artifact_path" {
  type = string
}

variable "tenant" {
  type        = string
  description = "Tenant short name — 'corp' or 'qa'. Used for tagging and validation."
}

variable "enforce" {
  type        = bool
  description = "If true, assignments use enforcement_mode Default. If false, DoNotEnforce."
}

variable "management_group_id" {
  type        = string
  description = "Management group ID that policy definitions and initiatives will be created in."
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID used as default scope for subscription-scoped assignments."
}

variable "assignment_ids" {
  type        = list(string)
  default     = []
  description = "User-assigned managed identity resource IDs for assignments. If empty, assignments use SystemAssigned identity."
}