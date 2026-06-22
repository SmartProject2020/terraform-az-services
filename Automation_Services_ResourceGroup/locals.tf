locals {
  rg_name      = upper("${var.PLAQUE}-${var.SETTING}-${var.APPLICATION_ID}-${var.ENV}-RG${var.resource_group_inc}")
  backup_policy = var.ENV == "PRD" ? "PROD" : "NONPROD"
}
