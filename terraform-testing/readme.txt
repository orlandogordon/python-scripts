  Invocation: terraform plan -var branch=development (with
  TF_VAR_bofa_qa_tenant_id/TF_VAR_bofa_qa_subscription_id etc. exported in the env). The dev branch
   has only the development artifact, so only that module activates; the staging branch would      
  activate three.

  Joins implemented in the module:
  - initiative.definitions[].policy_name → azurerm_policy_definition.this[<that hash>]
  - assignment.policy_definition → azurerm_policy_set_definition.this[<that hash>]
  - Assignment parameters reduced from { value, type, allowedValues, ... } down to { value }       
  because that's all the Azure assignment API accepts

  Things I made decisions on rather than ask (call out anything you want changed):
  1. Target MG override: every resource is scoped to the entry's target from
  deployment_locations.yml, ignoring the management_group_name inside each YAML. This is what makes
   one rule yml deployable to multiple targets. If you'd rather the YAML's own MG win, swap        
  local.mg_id for a per-resource lookup.
  2. Alias filtering: not implemented yet. All initiative/assignment files in an artifact folder   
  are deployed regardless of alias. You said the rule was "alias only applies when the deploying   
  tenant matches the current target," which I still don't fully understand — happy to add the      
  filter once it's nailed down.
  3. Metadata merging: I merge metadata, company_metadata, bofa_metadata, and pnc_metadata into the
   Azure metadata blob. If *_metadata should be excluded, easy to drop.
  4. Adding new tenants/artifacts is a two-step manual edit (provider alias + module block).       
  Terraform's static provider requirement makes a fully dynamic version not possible without code  
  generation.
  5. fileset glob is rules/*/*.yml — one service-folder level deep. If you need deeper nesting,    
  switch to a module-side helper or pin a fixed depth pattern.