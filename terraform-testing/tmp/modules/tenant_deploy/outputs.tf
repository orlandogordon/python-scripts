output "policy_definition_ids" {
  value = { for k, v in azurerm_policy_definition.this : k => v.id }
}

output "policy_set_definition_ids" {
  value = { for k, v in azurerm_policy_set_definition.this : k => v.id }
}

output "assignment_ids" {
  value = { for k, v in azurerm_management_group_policy_assignment.this : k => v.id }
}
