output "keyvault_id" {
  description = "ID du Key Vault"
  value       = module.keyvault.keyvault_id
}

output "keyvault_name" {
  description = "Nom du Key Vault"
  value       = module.keyvault.keyvault_name
}

output "keyvault_uri" {
  description = "URI du Key Vault"
  value       = module.keyvault.keyvault_uri
}
