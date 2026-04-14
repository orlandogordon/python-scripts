locals {
  # Find all deployment_vars.yml files under artifacts/
  deployment_files = fileset("${path.root}/../artifacts", "*/deployment_vars.yml")

  # Parse each file, keyed by the artifact directory name
  artifacts = {
    for f in local.deployment_files :
    dirname(f) => merge(
      yamldecode(file("${path.root}/../artifacts/${f}")),
      {
        artifact_name = dirname(f)
        artifact_path = "${path.root}/../artifacts/${dirname(f)}"
      }
    )
  }

  # Split by tenant — these maps are the inputs to the module for_each calls
  artifacts_corp = {
    for name, cfg in local.artifacts :
    name => cfg if cfg.tenant == "corp"
  }

  artifacts_qa = {
    for name, cfg in local.artifacts :
    name => cfg if cfg.tenant == "qa"
  }
}

# Validation: every artifact must declare a valid tenant
check "valid_tenants" {
  assert {
    condition = alltrue([
      for name, cfg in local.artifacts :
      contains(["corp", "qa"], cfg.tenant)
    ])
    error_message = "Every artifacts/*/deployment_vars.yml must set 'tenant' to either 'corp' or 'qa'. Offending artifacts: ${join(", ", [for name, cfg in local.artifacts : name if !contains(["corp", "qa"], lookup(cfg, "tenant", ""))])}"
  }
}

# Validation: every artifact must have the required deployment fields
check "required_fields" {
  assert {
    condition = alltrue([
      for name, cfg in local.artifacts :
      alltrue([
        for field in ["enforce", "override_policy_management_group", "subscription_id"] :
        contains(keys(cfg), field)
      ])
    ])
    error_message = "Every deployment_vars.yml must include: enforce, override_policy_management_group, subscription_id"
  }
}