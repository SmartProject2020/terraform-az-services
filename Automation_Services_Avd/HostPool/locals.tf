locals {
  # Conventions de nommage
  # RG : {PLAQUE}-{SETTING}-{POOL_TYPE}{POOL_ID}-{ENV}-RG01 (1 RG par pool, suffixe fixe)
  rg_name = upper("${var.PLAQUE}-${var.SETTING}-${var.POOL_TYPE}${var.POOL_ID}-${var.ENV}-RG01")

  # Host Pool : {POOL_TYPE}{POOL_ID} — POOL_ID inclut l'increment (ex: ADMSYS1)
  host_pool_name = upper("${var.POOL_TYPE}${var.POOL_ID}")

  # M = Multisession -> Pooled / P = Personnel -> Personal (cf. TAD section 6.1)
  avd_type = var.POOL_TYPE == "M" ? "Pooled" : "Personal"

  # Backup policy : derive de l environnement
  backup_policy = var.ENV == "PRD" ? "PROD" : "NOBACKUP"

  # ============================================================================
  # Reseau — module Avd/Subnet (HLD section 9, 1 Host Pool = 1 subnet dedie)
  # Table de correspondance SETTING+NETWORK_ZONE -> VNET/RG cible, confirmee
  # par l'equipe reseau (cf. memoire architecture v2).
  # ============================================================================
  network_lookup = {
    "PRD-standard" = {
      resource_group_name  = "EM50-PRD-AVDAZ-PRD-RG01"
      virtual_network_name = "EM50-PRD-AVDAZ-VNET01"
      vnet_address_space   = "10.202.0.0/18"
      newbits              = 6
      route_table_name     = "EM50-PRD-AVDAZ-RT01"
    }
    "PRD-critical" = {
      resource_group_name  = "EM50-PRD-AVDAZ-PRD-RG01"
      virtual_network_name = "EM50-PRD-AVDAZ-VNET02"
      vnet_address_space   = "10.202.64.0/20"
      newbits              = 4
      route_table_name     = "EM50-PRD-AVDAZ-RT01"
    }
    "NPR-standard" = {
      resource_group_name  = "EM50-NPR-AVDAZ-TST-RG01"
      virtual_network_name = "EM50-NPR-AVDAZ-VNET01"
      vnet_address_space   = "10.202.80.0/20"
      newbits              = 4
      route_table_name     = "EM50-NPR-AVDAZ-RT01"
    }
  }

  network_key = "${var.SETTING}-${var.NETWORK_ZONE}"

  # Acces direct (sans lookup/default) : si la combinaison SETTING-NETWORK_ZONE
  # n'existe pas encore, Terraform echoue avec un message explicite.
  network = local.network_lookup[local.network_key]

  # Convention : {PLAQUE}-{SETTING}-{POOL_TYPE}{POOL_ID}-SNET01
  # 1 subnet par pool -> suffixe toujours 01
  subnet_name = upper("${var.PLAQUE}-${var.SETTING}-${var.POOL_TYPE}${var.POOL_ID}-SNET01")

  # ============================================================================
  # Stockage FSLogix — 1 Storage Account (Premium FileStorage) + 1 fileshare
  # par Host Pool. Redondance derivee de l environnement : PRD -> ZRS, sinon LRS.
  # ============================================================================
  storage_redundancy = var.ENV == "PRD" ? "ZRS" : "LRS"

  # Convention : {plaque}{setting}{pool_type}{pool_id}sta01  (<=24 chars, lowercase)
  # 1 storage account par pool -> suffixe toujours 01
  storage_account_name = lower("${var.PLAQUE}${var.SETTING}${var.POOL_TYPE}${var.POOL_ID}sta01")

  # Quota FSLogix : NB_USERS * 5 Go, minimum 100 Go (contrainte Premium FileStorage)
  fslogix_quota_gb = max(var.NB_USERS * 5, 100)

  # Nommage Private Endpoint et NIC : suffixe toujours 01 (1 PE par pool)
  pe_name  = upper("${var.PLAQUE}-${var.SETTING}-${var.POOL_TYPE}${var.POOL_ID}-PE01")
  nic_name = upper("${var.PLAQUE}-${var.SETTING}-${var.POOL_TYPE}${var.POOL_ID}-NIC01")

  # Scaling Plan : suffixe toujours 01 (1 SP par pool, Pooled et Personal)
  scaling_plan_name = upper("${var.PLAQUE}-${var.SETTING}-${var.POOL_TYPE}${var.POOL_ID}-SP01")

  # ============================================================================
  # ScalingPlan Personal (azapi — cf. main.tf) : pas de valeurs precisees au HLD
  # (sections 12.2.1/12.2.2 vides), retenu avec Ramzi le 2026-07-10 :
  # Deallocate sur disconnect ET logoff, sur toutes les periodes, 30 min de delai.
  # Horaires alignes sur le schedule Pooled ("Semaine", Lundi-Vendredi).
  # ============================================================================
  scaling_plan_personal_schedule_name       = "Semaine"
  scaling_plan_personal_days_of_week        = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  scaling_plan_personal_start_vm_on_connect = var.start_vm_on_connect ? "Enable" : "Disable"

  scaling_plan_personal_period_defaults = {
    actionOnDisconnect        = "Deallocate"
    actionOnLogoff            = "Deallocate"
    minutesToWaitOnDisconnect = 30
    minutesToWaitOnLogoff     = 30
  }

  # Fuseau horaire du ScalingPlan derive de la plaque (valeurs Windows timezone)
  # AM50 et AP50 : a confirmer avec les equipes regionales
  scaling_plan_timezone_lookup = {
    "EM50" = "Romance Standard Time"
    "GL50" = "Romance Standard Time"
    "AM50" = "Eastern Standard Time"
    "AP50" = "Singapore Standard Time"
  }
  scaling_plan_time_zone = lookup(local.scaling_plan_timezone_lookup, var.PLAQUE, "Romance Standard Time")

  # ============================================================================
  # Key Vault AVD partage (1 par subscription/env — APPLICATION_ID fixe AVD00)
  # Convention : ${PLAQUE}-${SETTING}-AVD00-KV01 / ${PLAQUE}-${SETTING}-AVD00-${SETTING}-RG01
  # Surchargeables via KV_NAME / KV_RESOURCE_GROUP_NAME si besoin.
  # ============================================================================
  # TEMPORAIRE (test itmatched) : KV02/POC-RG01 au lieu du defaut KV01/NPR-RG01 —
  # a reverter apres validation, cf. memoire (KV01 indisponible sur itmatched,
  # nom pris globalement par le vrai KV du tenant Servier).
  kv_name                = upper(var.KV_NAME != null && var.KV_NAME != "" ? var.KV_NAME : "${var.PLAQUE}-${var.SETTING}-AVD00-KV02")
  kv_resource_group_name = upper(var.KV_RESOURCE_GROUP_NAME != null && var.KV_RESOURCE_GROUP_NAME != "" ? var.KV_RESOURCE_GROUP_NAME : "${var.PLAQUE}-${var.SETTING}-AVD00-POC-RG01")
  sa_public_network_access_enabled = true
  common_tags = {
    "managed-by"          = "terraform"
    "module"              = "avd-hostpool"
    "application-id"      = var.APPLICATION_ID
    "backup-policy"       = local.backup_policy
    "servier-environment" = var.servier_environment
  }
}
