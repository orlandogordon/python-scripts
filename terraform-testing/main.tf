locals {
  rules_glob = "${var.policies_root}/${var.target_env}/rules/**/*.yml"
  rule_files = fileset(path.module, local.rules_glob)

  rules_raw = {
    for f in local.rule_files :
    f => yamldecode(file("${path.module}/${f}"))
  }

  # Skip anything flagged exclude: true; key by the YAML `name`.
  rules = {
    for f, r in local.rules_raw :
    tostring(r.name) => r
    if try(r.exclude, false) != true
  }

  tenant_root_mg_id = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

resource "azurerm_policy_definition" "this" {
  for_each = local.rules

  name                = each.key
  policy_type         = try(each.value.type, "Custom")
  mode                = try(each.value.mode, "All")
  display_name        = try(each.value.display_name, each.key)
  description         = try(each.value.description, try(each.value.descripiton, null))
  management_group_id = local.tenant_root_mg_id

  metadata = jsonencode(merge(
    try(each.value.metadata, {}),
    try(each.value.company_metadata, {}),
  ))

  policy_rule = jsonencode(each.value.rule)
  parameters  = jsonencode(try(each.value.parameters, {}))
}
