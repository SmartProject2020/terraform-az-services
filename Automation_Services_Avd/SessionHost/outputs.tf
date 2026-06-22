output "resource_group_name" {
  description = "Resource Group du Host Pool dans lequel les Session Hosts sont deployes"
  value       = local.resource_group_name
}

output "host_pool_name" {
  description = "Nom du Host Pool auquel les Session Hosts sont rattaches"
  value       = local.host_pool_name
}

output "session_host_names" {
  description = "Noms des VM Session Host"
  value       = module.session_host.session_host_names
}

output "computer_names" {
  description = "Noms Windows (computer_name, tronques a 15 caracteres)"
  value       = module.session_host.computer_names
}
