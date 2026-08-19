locals {
  backup_policy = var.ENV == "PRD" ? "PROD" : "NONPROD"
 
  # Workspace du module racine HostPool correspondant (meme convention que son workflow)
  host_pool_workspace = "${var.PLAQUE}-${var.ENV}-${var.APPLICATION_ID}-hostpool-${var.HOST_POOL_NAME}"
 
  host_pool_name      = data.terraform_remote_state.host_pool.outputs.host_pool_name
  resource_group_name = data.terraform_remote_state.host_pool.outputs.resource_group_name
  registration_token  = data.terraform_remote_state.host_pool.outputs.registration_token
 
  # Subnet dedie au Host Pool (module Avd/Subnet, cree par Automation_Services_Avd_HostPool)
  subnet_id    = data.terraform_remote_state.host_pool.outputs.subnet_id
  vnet_rg_name = regex("resourceGroups/([^/]+)/", local.subnet_id)[0]
 
  # Prefixe de nommage des Session Hosts — TAD section 2.2 : <AVD><HostPoolID>-<n>
  name_prefix = "AVD${local.host_pool_name}"

  # POOL_TYPE derive du HOST_POOL_NAME (convention HLD v0.1 : <M|P><PoolID><version>,
  # ex: MADMSYS1) — evite de redemander une info deja contenue dans le nom du pool
  # et le risque de mismatch M/P vs le pool reel.
  pool_type = substr(upper(var.HOST_POOL_NAME), 0, 1)

  # Compte admin local technique — toujours le meme (DI SOP securite Servier : pas
  # de compte admin permanent autre que ce compte technique). Deja fige en dur dans
  # le nom du secret Key Vault cote HostPool ("avdlocaladmin-<POOL>").
  admin_username = "avdlocaladmin"

  # ============================================================================
  # Dimensionnement (CR workshop, cf. memoire architecture v2) — sizing par
  # WORKLOAD_TYPE (pools Personal) ou USER_TIER (pools MultiSession).
  # ============================================================================
  workload_lookup = {
    "Light"          = "Standard_D2s_v5"
    "Standard"       = "Standard_D4s_v5"
    "Standard+Teams" = "Standard_D8s_v5"
    "Heavy"          = "Standard_E8s_v5"
    "Power"          = "Standard_E16s_v5"
  }
 
  # vm_count = borne basse pour les paliers a plage ouverte (50-100/100-250/250+),
  # surchargeable via vm_count_override.
  user_tier_lookup = {
    "0-10"    = { vm_size = "Standard_D4s_v5", vm_count = 1 }
    "10-30"   = { vm_size = "Standard_D4s_v5", vm_count = 2 }
    "30-50"   = { vm_size = "Standard_D4s_v5", vm_count = 3 }
    "50-100"  = { vm_size = "Standard_D8s_v5", vm_count = 5 }
    "100-250" = { vm_size = "Standard_D8s_v5", vm_count = 8 }
    "250+"    = { vm_size = "Standard_D8s_v5", vm_count = 15 }
  }
 
  sizing = local.pool_type == "P" ? {
    vm_size            = local.workload_lookup[var.WORKLOAD_TYPE]
    session_host_count = coalesce(var.vm_count_override, var.USER_COUNT)
    } : {
    vm_size            = local.user_tier_lookup[var.USER_TIER].vm_size
    session_host_count = coalesce(var.vm_count_override, local.user_tier_lookup[var.USER_TIER].vm_count)
  }
 
  vm_size            = coalesce(var.vm_size_override, local.sizing.vm_size)
  session_host_count = local.sizing.session_host_count
 
  # ============================================================================
  # Image marketplace par defaut selon POOL_TYPE (surchargeable via var.image_*).
  # Personal -> Windows 11 Enterprise single-session. MultiSession -> Windows 11
  # Enterprise multi-session + Microsoft 365 Apps (version pinnee, cf. offre office-365).
  # ============================================================================
  image_defaults = {
    "P" = { publisher = "microsoftwindowsdesktop", offer = "windows-11", sku = "win11-25h2-ent", version = "latest" }
    "M" = { publisher = "microsoftwindowsdesktop", offer = "office-365", sku = "win11-25h2-avd-m365", version = "26200.8655.260609" }
  }
 
  image_publisher = local.image_defaults[local.pool_type].publisher
  image_offer     = local.image_defaults[local.pool_type].offer
  image_sku       = local.image_defaults[local.pool_type].sku
  image_version   = coalesce(var.image_version, local.image_defaults[local.pool_type].version)
 
  # ============================================================================
  # Availability Zones — 3 AZ en PRD (resilience), aucune en DEV. Repartition
  # round-robin des Session Hosts sur les zones disponibles (cf. child module).
  # ============================================================================
  zones = var.ENV == "PRD" ? ["1", "2", "3"] : []
 
  # ============================================================================
  # FSLogix — chemin UNC derive du fileshare FSLogix du Host Pool (module
  # StorageAccount + Fileshare, deploye par Automation_Services_Avd_HostPool).
  # ============================================================================
  fslogix_storage_account_name = data.terraform_remote_state.host_pool.outputs.fslogix_storage_account_name
  fslogix_fileshare_name       = data.terraform_remote_state.host_pool.outputs.fslogix_fileshare_name
  fslogix_vhd_locations        = "\\\\${local.fslogix_storage_account_name}.file.core.windows.net\\${local.fslogix_fileshare_name}\\profiles"
}
 