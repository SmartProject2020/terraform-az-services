
locals {
  rg_name              = upper("${var.PLAQUE}-${var.SETTING}-${var.APPLICATION_ID}-${var.ENV}-RG${var.RESOURCE_GROUP_INC}")
  storage_account_name = lower("${var.PLAQUE}${var.ENV}${var.APPLICATION_ID}sta${var.STORAGE_ACCOUNT_INC}")

  backup_policy = var.SETTING == "PRD" ? "PROD" : "NONPROD"

  # StorageV2 acquisition : GRS en PRD pour la résilience, LRS en NPR (coût)
  storage_replication_type = var.SETTING == "PRD" ? "GRS" : "LRS"

  network_rules_action          = "Allow"
  public_network_access_enabled = true
  sftp_enabled                  = false
  is_hns_enabled                = false
}