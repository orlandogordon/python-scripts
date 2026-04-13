# locals.tf (root)

locals {
  # Find all artifact config files. fileset returns paths relative to the path argument.
  artifact_config_files = fileset("${path.root}/../artifacts", "*/config.yml")

  # Parse each config.yml into a map keyed by the artifact directory name.
  # The directory name is the part of the path before "/config.yml".
  artifacts = {
    for cfg_path in local.artifact_config_files :
    dirname(cfg_path) => merge(
      yamldecode(file("${path.root}/../artifacts/${cfg_path}")),
      {
        # Inject the artifact directory name and absolute path so the module
        # can locate its own rules/initiatives/assignments folders.
        artifact_dir  = dirname(cfg_path)
        artifact_path = "${path.root}/../artifacts/${dirname(cfg_path)}"
      }
    )
  }

  # Validation: catch missing required fields at plan time with clear errors.
  # (See validation block below for the actual enforcement.)
  required_config_fields = ["tenant_short", "target_short", "management_group_name"]
}

# Plan-time validation — fails with a clear message if any config.yml is missing required fields.
check "all_configs_have_required_fields" {
  assert {
    condition = alltrue([
      for name, cfg in local.artifacts :
      alltrue([for field in local.required_config_fields : contains(keys(cfg), field)])
    ])
    error_message = "One or more artifacts/*/config.yml files are missing required fields: ${join(", ", local.required_config_fields)}"
  }
}