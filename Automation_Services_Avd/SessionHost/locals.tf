locals {
  backup_policy = var.ENV == "PRD" ? "PROD" : "NONPROD"

  # Workspace du module racine HostPool correspondant (meme convention que son workflow)
  host_pool_workspace = "${var.PLAQUE}-${var.ENV}-${var.APPLICATION_ID}-hostpool-${var.HOST_POOL_NAME}"

  host_pool_name      = data.terraform_remote_state.host_pool.outputs.host_pool_name
  resource_group_name = data.terraform_remote_state.host_pool.outputs.resource_group_name
  registration_token  = data.terraform_remote_state.host_pool.outputs.registration_token

  # Subnet dedie au Host Pool (module Avd/Subnet, cree par Automation_Services_Avd_HostPool)
  subnet_id = data.terraform_remote_state.host_pool.outputs.subnet_id

  # Prefixe de nommage des Session Hosts — TAD section 2.2 : <AVD><HostPoolID>-<n>
  name_prefix = "AVD${local.host_pool_name}"

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

  sizing = var.POOL_TYPE == "P" ? {
    vm_size            = local.workload_lookup[var.WORKLOAD_TYPE]
    session_host_count = var.USER_COUNT
    } : {
    vm_size            = local.user_tier_lookup[var.USER_TIER].vm_size
    session_host_count = coalesce(var.vm_count_override, local.user_tier_lookup[var.USER_TIER].vm_count)
  }

  vm_size            = local.sizing.vm_size
  session_host_count = local.sizing.session_host_count

  # ============================================================================
  # Availability Zones — 3 AZ en PRD (resilience), aucune en DEV. Repartition
  # round-robin des Session Hosts sur les zones disponibles (cf. child module).
  # ============================================================================
  zones = var.ENV == "PRD" ? ["1", "2", "3"] : []
}
