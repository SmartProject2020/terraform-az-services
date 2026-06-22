# ==============================================================================
# Outputs du root Storageaccount
# Exposes pour debug et integration avec d autres workflows
# ==============================================================================

output "resource_group_name" {
  description = "Nom du Resource Group"
  value       = local.rg_name
}

output "storage_account_id" {
  description = "ID complet du Storage Account"
  value       = module.storage_account.storage_account_id
}

output "storage_account_name" {
  description = "Nom du Storage Account"
  value       = module.storage_account.storage_account_name
}

output "primary_blob_endpoint" {
  description = "Endpoint primaire blob du Storage Account"
  value       = module.storage_account.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Endpoint primaire fileshares du Storage Account"
  value       = module.storage_account.primary_file_endpoint
}

output "private_endpoint_name" {
  description = "Nom du Private Endpoint (vide si storage_account_type = public)"
  value       = local.endpoint_name
}
