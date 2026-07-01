output "resource_group_name" {
  description = "Nom du Resource Group du Host Pool"
  value       = data.azurerm_resource_group.rg.name
}

output "host_pool_id" {
  description = "ID du Host Pool"
  value       = module.host_pool.host_pool_id
}

output "host_pool_name" {
  description = "Nom du Host Pool"
  value       = module.host_pool.host_pool_name
}

output "registration_token" {
  description = "Token d'enregistrement des Session Hosts (sensible) — a consommer par Automation_Services_Avd_SessionHost"
  value       = module.host_pool.registration_token
  sensitive   = true
}

output "registration_expiration_date" {
  description = "Date d'expiration du token d'enregistrement (RFC3339)"
  value       = module.host_pool.registration_expiration_date
}

output "subnet_id" {
  description = "ID du subnet dedie au Host Pool — a consommer par Automation_Services_Avd_SessionHost"
  value       = module.subnet.subnet_id
}

output "subnet_address_prefix" {
  description = "CIDR /24 alloue automatiquement au Host Pool"
  value       = module.subnet.subnet_address_prefix
}

output "vm_location" {
  description = "Region Azure pour les VMs/NICs (= region du VNET, peut differer de la region AVD)"
  value       = module.subnet.vnet_location
}

output "route_table_id" {
  description = "ID de la Route Table associee au subnet du Host Pool"
  value       = module.subnet.route_table_id
}

output "fslogix_storage_account_name" {
  description = "Nom du Storage Account FSLogix dedie au Host Pool"
  value       = module.storage_account.storage_account_name
}

output "fslogix_fileshare_name" {
  description = "Nom du fileshare FSLogix (avec prefixe APPLICATION_ID) — a consommer par Automation_Services_Avd_SessionHost (AD join FSLogix)"
  value       = module.fileshare.fileshare_names["fslogix"]
}

output "kv_id" {
  description = "ID du Key Vault AVD partage — a consommer par Automation_Services_Avd_SessionHost pour lire le mot de passe admin local"
  value       = data.azurerm_key_vault.avd.id
}

output "admin_password_secret_name" {
  description = "Nom du secret Key Vault contenant le mot de passe admin local des Session Hosts de ce pool"
  value       = azurerm_key_vault_secret.admin.name
}

output "users_group_id" {
  description = "Object ID du groupe Entra ID CB-GO-AVD<POOL>-USERS — a consommer par Task #7 pour le role Desktop Virtualization User sur l'AppGroup"
  value       = azuread_group.users.object_id
}

output "devices_group_id" {
  description = "Object ID du groupe Entra ID CB-GO-AVD<POOL>-DEVICES"
  value       = azuread_group.devices.object_id
}

output "app_group_id" {
  description = "ID du Desktop Application Group (<POOL_NAME>-DAG)"
  value       = azurerm_virtual_desktop_application_group.dag.id
}

output "workspace_id" {
  description = "ID du Workspace AVD (<POOL_NAME>)"
  value       = azurerm_virtual_desktop_workspace.ws.id
}

output "private_endpoint_id" {
  description = "ID du Private Endpoint FSLogix ({PLAQUE}-{SETTING}-{POOL_ID}-PE{NN})"
  value       = module.private_endpoint.endpoint_id
}
