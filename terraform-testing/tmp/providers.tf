# providers.tf

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Default provider (unused by resources, but required to exist).
# Points at corp so any accidental unaliased reference fails loudly
# in corp rather than silently succeeding.
provider "azurerm" {
  features {}
  tenant_id                   = var.corp_tenant_id
  subscription_id             = var.corp_subscription_id
  client_id                   = var.corp_client_id
  client_certificate_path     = var.corp_cert_path
  client_certificate_password = var.corp_cert_password
}

provider "azurerm" {
  alias = "corp"
  features {}
  tenant_id                   = var.corp_tenant_id
  subscription_id             = var.corp_subscription_id
  client_id                   = var.corp_client_id
  client_certificate_path     = var.corp_cert_path
  client_certificate_password = var.corp_cert_password
}

provider "azurerm" {
  alias = "qa"
  features {}
  tenant_id                   = var.qa_tenant_id
  subscription_id             = var.qa_subscription_id
  client_id                   = var.qa_client_id
  client_certificate_path     = var.qa_cert_path
  client_certificate_password = var.qa_cert_password
}