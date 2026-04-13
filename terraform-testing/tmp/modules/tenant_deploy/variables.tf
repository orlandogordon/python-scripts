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
  type        = string
  description = "Name of the artifact directory (e.g., 'staging_qa'). Used as a prefix for resource names to avoid collisions across module instances."
}

variable "config" {
  type        = any
  description = "Parsed contents of the artifact's config.yml, with artifact_dir and artifact_path fields injected by the root module."
}

variable "artifact_path" {
  type        = string
  description = "Absolute path to the artifact directory. The module reads rules/, initiatives/, and assignments/ subfolders from here."
}