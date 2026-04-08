terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  alias           = "bofa"
  features {}
  tenant_id       = var.bofa_tenant_id
  subscription_id = var.bofa_subscription_id
}

provider "azurerm" {
  alias           = "bofa_qa"
  features {}
  tenant_id       = var.bofa_qa_tenant_id
  subscription_id = var.bofa_qa_subscription_id
}
