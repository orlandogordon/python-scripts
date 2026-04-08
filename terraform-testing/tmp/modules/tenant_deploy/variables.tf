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
