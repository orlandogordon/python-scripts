# modules/deployer/locals.tf

locals {
  # Prefix that ensures resource names are unique per module instance.
  # Without this, two artifacts deploying to the same management group would
  # collide on policy definition names.
  prefix = "${var.artifact_name}-"

  # Common tags merged from config.yml plus an injected source tag
  common_tags = merge(
    lookup(var.config, "common_tags", {}),
    {
      artifact_source = var.artifact_name
    }
  )

  # === Read policy definition files ===
  rule_files = fileset(var.artifact_path, "rules/*.json")

  policy_list = [
    for f in local.rule_files : merge(
      jsondecode(file("${var.artifact_path}/${f}")),
      {
        file_name = f
        fmt_name  = "${local.prefix}${trimsuffix(basename(f), ".json")}"
        # Re-add any other fields your existing code expects in policy_list elements
        management_group_name = var.config.management_group_name
        pnc_metadata          = lookup(var.config, "pnc_metadata", {})
      }
    )
  ]

  # === Read initiative files ===
  initiative_files = fileset(var.artifact_path, "initiatives/*.json")

  policy_initiative_list = [
    for f in local.initiative_files : merge(
      jsondecode(file("${var.artifact_path}/${f}")),
      {
        file_name             = f
        fmt_name              = "${local.prefix}${trimsuffix(basename(f), ".json")}"
        management_group_name = var.config.management_group_name
        pnc_metadata          = lookup(var.config, "pnc_metadata", {})
        # parameter_sha computed however your existing code does it
        parameter_sha         = substr(sha256(jsonencode(lookup(jsondecode(file("${var.artifact_path}/${f}")), "parameters", {}))), 0, 8)
      }
    )
  ]

  # === Read assignment files ===
  assignment_files = fileset(var.artifact_path, "assignments/*.json")

  # Split into mgmt-group vs subscription assignments based on whatever
  # field your assignment JSONs use to indicate scope type.
  all_assignments = [
    for f in local.assignment_files : merge(
      jsondecode(file("${var.artifact_path}/${f}")),
      {
        file_name = f
        fmt_name  = "${local.prefix}${trimsuffix(basename(f), ".json")}"
        scope     = jsondecode(file("${var.artifact_path}/${f}")).scope
        # Reference the initiative's fmt_name so the module's azurerm_policy_set_definition
        # for_each key matches what the assignment expects to look up
        definition_fmt_name = "${local.prefix}${jsondecode(file("${var.artifact_path}/${f}")).initiative_name}"
      }
    )
  ]

  management_group_assignment_list = [
    for a in local.all_assignments : a if a.scope_type == "management_group"
  ]

  resource_assignment_list = [
    for a in local.all_assignments : a if a.scope_type == "subscription"
  ]
}