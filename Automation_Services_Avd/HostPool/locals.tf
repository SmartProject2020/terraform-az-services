locals {
  # Conventions de nommage
  rg_name = upper("${var.PLAQUE}-${var.SETTING}-${var.APPLICATION_ID}-${var.ENV}-RG${var.RESOURCE_GROUP_INC}")

  # Convention HLD v0.1 : <M|P><PoolID><version>  (ex: MADMSYS1)
  host_pool_name = upper("${var.POOL_TYPE}${var.POOL_ID}${var.POOL_VERSION}")

  # M = Multisession -> Pooled / P = Personnel -> Personal (cf. TAD section 6.1)
  avd_type = var.POOL_TYPE == "M" ? "Pooled" : "Personal"

  # Backup policy : derive de l environnement
  backup_policy = var.ENV == "PRD" ? "PROD" : "NONPROD"

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
    }
    "PRD-critical" = {
      resource_group_name  = "EM50-PRD-AVDAZ-PRD-RG01"
      virtual_network_name = "EM50-PRD-AVDAZ-VNET02"
      vnet_address_space   = "10.202.64.0/20"
      newbits              = 4
    }
    "NPR-standard" = {
      resource_group_name  = "EM50-NPR-AVDAZ-TST-RG01"
      virtual_network_name = "EM50-NPR-AVDAZ-VNET01"
      vnet_address_space   = "10.202.80.0/20"
      newbits              = 4
    }
  }

  network_key = "${var.SETTING}-${var.NETWORK_ZONE}"

  # Acces direct (sans lookup/default) : si la combinaison SETTING-NETWORK_ZONE
  # n'existe pas encore (ex: NPR-critical, *-POC), Terraform echoue avec un
  # message explicite mentionnant la cle manquante.
  network = local.network_lookup[local.network_key]

  subnet_name = "${local.host_pool_name}-SNET01"
  nsg_name    = "${local.host_pool_name}-NSG01"

  # ============================================================================
  # Stockage FSLogix — 1 Storage Account (Premium FileStorage) + 1 fileshare
  # "fslogix" par Host Pool. Redondance derivee de l environnement (pas un
  # champ formulaire) : PRD -> ZRS, sinon LRS.
  # ============================================================================
  storage_redundancy = var.ENV == "PRD" ? "ZRS" : "LRS"

  # Convention de nommage : lowercase, <=24 caracteres (contrainte Azure)
  storage_account_name = lower("${var.PLAQUE}${var.ENV}${local.host_pool_name}fsl")

  # ============================================================================
  # Key Vault AVD partage (1 par subscription/env — APPLICATION_ID fixe AVD00)
  # Convention : ${PLAQUE}-${SETTING}-AVD00-KV01 / ${PLAQUE}-${SETTING}-AVD00-${SETTING}-RG01
  # Surchargeables via KV_NAME / KV_RESOURCE_GROUP_NAME si besoin.
  # ============================================================================
  kv_name                = upper(var.KV_NAME != null && var.KV_NAME != "" ? var.KV_NAME : "${var.PLAQUE}-${var.SETTING}-AVD00-KV01")
  kv_resource_group_name = upper(var.KV_RESOURCE_GROUP_NAME != null && var.KV_RESOURCE_GROUP_NAME != "" ? var.KV_RESOURCE_GROUP_NAME : "${var.PLAQUE}-${var.SETTING}-AVD00-${var.SETTING}-RG01")

  common_tags = merge(
    data.azurerm_resource_group.rg.tags,
    {
      "managed-by"          = "terraform"
      "module"              = "avd-hostpool"
      "application-id"      = var.APPLICATION_ID
      "backup-policy"       = local.backup_policy
      "servier-environment" = var.servier_environment
    }
  )
}
