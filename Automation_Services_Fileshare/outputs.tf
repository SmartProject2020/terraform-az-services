# ==============================================================================
# Outputs du root Fileshare
# ==============================================================================

output "storage_account_id" {
  description = "ID du Storage Account hote (lu via data source)"
  value       = data.azurerm_storage_account.sa.id
}

output "storage_account_name" {
  description = "Nom du Storage Account hote"
  value       = data.azurerm_storage_account.sa.name
}

output "fileshare_ids" {
  description = "Map des IDs des fileshares crees"
  value       = module.fileshares.fileshare_ids
}

output "fileshare_names" {
  description = "Map des noms finaux des fileshares (avec prefixe APPLICATION_ID)"
  value       = module.fileshares.fileshare_names
}

output "fileshare_resource_manager_ids" {
  description = "Map des Resource Manager IDs (utilises pour le AD join)"
  value       = module.fileshares.fileshare_resource_manager_ids
}
