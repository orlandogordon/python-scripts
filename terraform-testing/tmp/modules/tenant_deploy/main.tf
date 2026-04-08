terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm]
    }
  }
}

locals {
  mg_id = "/providers/Microsoft.Management/managementGroups/${var.target_mg}"

  # ---- rules / policy definitions ----
  rule_files = fileset(var.artifact_path, "rules/*/*.yml")

  rules_raw = {
    for f in local.rule_files :
    f => yamldecode(file("${var.artifact_path}/${f}"))
  }

  rules = {
    for f, r in local.rules_raw :
    tostring(r.name) => r
    if try(r.exclude, false) != true
  }

  # ---- initiatives / policy set definitions ----
  initiative_files = fileset(var.artifact_path, "initiatives/*.yml")

  initiatives = {
    for f in local.initiative_files :
    tostring(yamldecode(file("${var.artifact_path}/${f}")).name)
    => yamldecode(file("${var.artifact_path}/${f}"))
  }

  # ---- assignments ----
  assignment_files = fileset(var.artifact_path, "assignments/*.yml")

  assignments = {
    for f in local.assignment_files :
    tostring(yamldecode(file("${var.artifact_path}/${f}")).name)
    => yamldecode(file("${var.artifact_path}/${f}"))
  }
}

resource "azurerm_policy_definition" "this" {
  for_each = local.rules

  name                = each.key
  policy_type         = try(each.value.type, "Custom")
  mode                = try(each.value.mode, "All")
  display_name        = try(each.value.display_name, each.key)
  description         = try(each.value.description, try(each.value.descripiton, null))
  management_group_id = local.mg_id

  metadata = jsonencode(merge(
    try(each.value.metadata, {}),
    try(each.value.company_metadata, {}),
    try(each.value.bofa_metadata, {}),
    try(each.value.pnc_metadata, {}),
  ))

  policy_rule = jsonencode(each.value.rule)
  parameters  = jsonencode(try(each.value.parameters, {}))
}

resource "azurerm_policy_set_definition" "this" {
  for_each = local.initiatives

  name                = each.key
  policy_type         = try(each.value.type, "Custom")
  display_name        = try(each.value.display_name, each.key)
  description         = try(each.value.description, null)
  management_group_id = local.mg_id

  metadata = jsonencode(merge(
    try(each.value.metadata, {}),
    try(each.value.bofa_metadata, {}),
    try(each.value.pnc_metadata, {}),
  ))

  parameters = jsonencode(try(each.value.parameters, {}))

  dynamic "policy_definition_reference" {
    for_each = try(each.value.definitions, [])
    content {
      # Join: initiative.definitions[].policy_name == rule.name
      policy_definition_id = azurerm_policy_definition.this[tostring(policy_definition_reference.value.policy_name)].id
      reference_id         = tostring(policy_definition_reference.value.policy_name)
      parameter_values     = jsonencode(try(policy_definition_reference.value.parameters, {}))
    }
  }

  depends_on = [azurerm_policy_definition.this]
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = local.assignments

  name         = each.key
  display_name = try(each.value.display_name, each.key)
  description  = try(each.value.description, null)

  management_group_id = local.mg_id

  # Join: assignment.policy_definition == initiative.name
  policy_definition_id = azurerm_policy_set_definition.this[tostring(each.value.policy_definition)].id

  enforce = var.enforce

  # Assignment YAML stores parameters as { <key>: { value: <v>, ...definition fields } }.
  # The Azure API only wants { <key>: { value: <v> } } here, so reduce.
  parameters = jsonencode({
    for k, v in try(each.value.parameters, {}) :
    k => { value = v.value }
  })

  depends_on = [azurerm_policy_set_definition.this]
}
