output "development" {
  value = try(module.development[0], null)
}

output "staging_bofa_qa" {
  value = try(module.staging_bofa_qa[0], null)
}

output "staging_poc" {
  value = try(module.staging_poc[0], null)
}

output "staging_pok" {
  value = try(module.staging_pok[0], null)
}
