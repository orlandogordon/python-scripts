# main.tf (root)

module "deployer_corp" {
  source   = "./modules/deployer"
  for_each = local.artifacts_corp

  providers = {
    azurerm = azurerm.corp
  }

  artifact_name       = each.key
  artifact_path       = each.value.artifact_path

  tenant              = each.value.tenant
  enforce             = each.value.enforce
  management_group_id = each.value.override_policy_management_group
  subscription_id     = each.value.subscription_id
  assignment_ids      = lookup(each.value, "assignment_ids", [])
}

module "deployer_qa" {
  source   = "./modules/deployer"
  for_each = local.artifacts_qa

  providers = {
    azurerm = azurerm.qa
  }

  artifact_name       = each.key
  artifact_path       = each.value.artifact_path

  tenant              = each.value.tenant
  enforce             = each.value.enforce
  management_group_id = each.value.override_policy_management_group
  subscription_id     = each.value.subscription_id
  assignment_ids      = lookup(each.value, "assignment_ids", [])
}