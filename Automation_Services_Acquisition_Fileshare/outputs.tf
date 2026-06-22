output "resource_group_name" {
  description = "Nom du Resource Group cree ou existant"
  value       = module.rg.resource_group_name
}

output "storage_account_name" {
  description = "Nom du Storage Account"
  value       = module.storage_account.storage_account_name
}

output "storage_account_id" {
  description = "ID du Storage Account"
  value       = module.storage_account.storage_account_id
}

output "fileshares" {
  description = "Liste des fileshares crees"
  value       = module.fileshares.fileshare_names
}
