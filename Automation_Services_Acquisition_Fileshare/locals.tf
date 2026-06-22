
locals {
  rg_name              = upper("${var.PLAQUE}-${var.SETTING}-${var.APPLICATION_ID}-${var.ENV}-RG${var.RESOURCE_GROUP_INC}")
  storage_account_name = lower("${var.PLAQUE}${var.ENV}${var.APPLICATION_ID}sta${var.STORAGE_ACCOUNT_INC}")

  backup_policy = var.SETTING == "PRD" ? "PROD" : "NONPROD"
  network_rules_action          = "Allow"
  public_network_access_enabled = true
  sftp_enabled   = false
  is_hns_enabled = false
}