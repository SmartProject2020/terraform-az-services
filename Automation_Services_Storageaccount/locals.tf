locals {
  # Conventions de nommage
  rg_name              = upper("${var.PLAQUE}-${var.SETTING}-${var.APPLICATION_ID}-${var.ENV}-RG${var.RESOURCE_GROUP_INC}")
  storage_account_name = lower("${var.PLAQUE}${var.ENV}${var.APPLICATION_ID}sta${var.STORAGE_ACCOUNT_INC}")
  endpoint_name        = upper("${var.PLAQUE}-${var.ENV}-${var.APPLICATION_ID}-PE${coalesce(var.PE_INC, var.STORAGE_ACCOUNT_INC)}")

  # RG reel du SA : si SA_EXISTING_RESOURCE_GROUP est fourni, on l utilise (cas SA dans ancien RG)
  sa_resource_group_name = var.SA_EXISTING_RESOURCE_GROUP != "" ? var.SA_EXISTING_RESOURCE_GROUP : local.rg_name

  # Backup policy : derive du setting
  backup_policy = var.ENV == "PRD" ? "PROD" : "NONPROD"

  # Logique reseau
  network_rules_action          = var.STORAGE_ACCOUNT_TYPE == "private" ? "Deny" : "Allow"
  public_network_access_enabled = var.STORAGE_ACCOUNT_TYPE == "private" ? false : true

  # SFTP : autorise uniquement pour StorageV2 (jamais FileStorage ni BlobStorage)
  sftp_enabled   = var.STORAGE_ACCOUNT_KIND == "StorageV2" ? var.SFTP_ENABLED : false
  is_hns_enabled = local.sftp_enabled
}
