locals {
  # Convention de nommage du SA (doit correspondre exactement au workflow SA)
  storage_account_name = lower("${var.PLAQUE}${var.ENV}${var.APPLICATION_ID}sta${var.STORAGE_ACCOUNT_INC}")
  rg_name              = upper("${var.PLAQUE}-${var.SETTING}-${var.APPLICATION_ID}-${var.ENV}-RG${var.RESOURCE_GROUP_INC}")
  # RG reel du SA : si SA_EXISTING_RESOURCE_GROUP est fourni, on l utilise
  sa_resource_group_name = var.SA_EXISTING_RESOURCE_GROUP != "" ? var.SA_EXISTING_RESOURCE_GROUP : local.rg_name
}
