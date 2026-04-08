locals {
  deployment_locations = yamldecode(file("${path.module}/azure_policies/deployment_locations.yml"))
  branch_entries       = try(local.deployment_locations.branch[var.branch], [])
  entries_by_artifact  = { for e in local.branch_entries : e.artifact_name => e }
}

# One module call per known artifact_name. Each is gated by `count` so it only
# runs when the current branch's entries include that artifact_name. Adding a
# new tenant/artifact means: (1) add a provider alias in providers.tf, (2) add
# a new module block here.

module "development" {
  source = "./modules/tenant_deploy"
  count  = contains(keys(local.entries_by_artifact), "development") ? 1 : 0

  providers = {
    azurerm = azurerm.bofa_qa
  }

  artifact_path = "${path.module}/azure_policies/development"
  target_mg     = try(local.entries_by_artifact["development"].target, "")
  enforce       = try(local.entries_by_artifact["development"].enforce, true)
}

module "staging_bofa_qa" {
  source = "./modules/tenant_deploy"
  count  = contains(keys(local.entries_by_artifact), "staging_bofa-qa") ? 1 : 0

  providers = {
    azurerm = azurerm.bofa_qa
  }

  artifact_path = "${path.module}/azure_policies/staging_bofa-qa"
  target_mg     = try(local.entries_by_artifact["staging_bofa-qa"].target, "")
  enforce       = try(local.entries_by_artifact["staging_bofa-qa"].enforce, true)
}

module "staging_poc" {
  source = "./modules/tenant_deploy"
  count  = contains(keys(local.entries_by_artifact), "staging_poc") ? 1 : 0

  providers = {
    azurerm = azurerm.bofa
  }

  artifact_path = "${path.module}/azure_policies/staging_poc"
  target_mg     = try(local.entries_by_artifact["staging_poc"].target, "")
  enforce       = try(local.entries_by_artifact["staging_poc"].enforce, true)
}

module "staging_pok" {
  source = "./modules/tenant_deploy"
  count  = contains(keys(local.entries_by_artifact), "staging_pok") ? 1 : 0

  providers = {
    azurerm = azurerm.bofa
  }

  artifact_path = "${path.module}/azure_policies/staging_pok"
  target_mg     = try(local.entries_by_artifact["staging_pok"].target, "")
  enforce       = try(local.entries_by_artifact["staging_pok"].enforce, true)
}
