locals {
  rg_name       = upper("${var.PLAQUE}-${var.SETTING}-${var.APPLICATION_ID}-${var.ENV}-RG${var.RESOURCE_GROUP_INC}")
  kv_name       = upper("${var.PLAQUE}-${var.ENV}-${var.APPLICATION_ID}-KV${var.KEYVAULT_INC}")
  pe_name       = upper("${var.PLAQUE}-${var.ENV}-${var.APPLICATION_ID}-PE${var.PE_INC}")
  backup_policy = var.ENV == "PRD" ? "PROD" : "NONPROD"
}
