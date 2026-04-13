# providers.tf (root)

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Default provider — required even if unused, can be a no-op or one of the tenants
provider "azurerm" {
  features {}
  tenant_id                   = var.tenant_a_tenant_id
  subscription_id             = var.tenant_a_subscription_id
  client_id                   = var.tenant_a_client_id
  client_certificate_path     = var.tenant_a_cert_path
  client_certificate_password = var.tenant_a_cert_password
}

provider "azurerm" {
  alias                       = "tenant_a"
  features {}
  tenant_id                   = var.tenant_a_tenant_id
  subscription_id             = var.tenant_a_subscription_id
  client_id                   = var.tenant_a_client_id
  client_certificate_path     = var.tenant_a_cert_path
  client_certificate_password = var.tenant_a_cert_password
}

provider "azurerm" {
  alias                       = "tenant_b"
  features {}
  tenant_id                   = var.tenant_b_tenant_id
  subscription_id             = var.tenant_b_subscription_id
  client_id                   = var.tenant_b_client_id
  client_certificate_path     = var.tenant_b_cert_path
  client_certificate_password = var.tenant_b_cert_password
}

# Add another provider block per tenant as needed.