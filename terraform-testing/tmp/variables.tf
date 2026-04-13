variable "branch" {
  type        = string
  description = "Pipeline branch name. Selects which entries from deployment_locations.yml to deploy."
}

variable "bofa_tenant_id" {
  type        = string
  description = "Tenant ID for the BofA tenant. Set via TF_VAR_bofa_tenant_id."
}

variable "bofa_subscription_id" {
  type        = string
  description = "Subscription ID used by the azurerm provider when authing against BofA. Set via TF_VAR_bofa_subscription_id."
}

variable "bofa_qa_tenant_id" {
  type        = string
  description = "Tenant ID for the BofA-QA tenant. Set via TF_VAR_bofa_qa_tenant_id."
}

variable "bofa_qa_subscription_id" {
  type        = string
  description = "Subscription ID used by the azurerm provider when authing against BofA-QA. Set via TF_VAR_bofa_qa_subscription_id."
}





variable "tenant_a_tenant_id"        { type = string }
variable "tenant_a_subscription_id"  { type = string }
variable "tenant_a_client_id"        { type = string }
variable "tenant_a_cert_path"        { type = string, sensitive = true }
variable "tenant_a_cert_password"    { type = string, sensitive = true }

variable "tenant_b_tenant_id"        { type = string }
# ... same shape for tenant_b ...