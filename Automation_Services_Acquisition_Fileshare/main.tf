# ==============================================================================
# Root module : Automation_Services_Acquisition_Fileshare
#
# Cas d'usage : acquisition / intégration d'une entité externe.
# Ce module crée en CASCADE :
#   1. Resource Group        (si absent)
#   2. Storage Account       (FileStorage, toujours public pour AD join)
#   3. Azure File Shares     (liste dynamique)
# L'AD join est déclenché APRÈS l'apply par le workflow GHA
# (terraform-register-fileshare.yml via azure_ad_authentication=true).
# ==============================================================================


# ==============================================================================
# 1. Resource Group
# ==============================================================================
module "rg" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//ResourceGroup?ref=poc"

  name                = local.rg_name
  location            = var.location
  application_id      = var.APPLICATION_ID
  backup_policy       = local.backup_policy
  servier_environment = var.servier_environment
}

# ==============================================================================
# 2. Storage Account (FileStorage, public, Standard LRS)
# ==============================================================================
module "storage_account" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//StorageAccount?ref=poc"

  resource_group_name                    = local.rg_name
  storage_account_name                   = local.storage_account_name
  storage_account_tier                   = var.STORAGE_ACCOUNT_TIER
  storage_account_kind                   = var.STORAGE_ACCOUNT_KIND
  storage_account_replication_type       = var.STORAGE_ACCOUNT_REPLICATION_TYPE
  storage_account_access_tier            = var.STORAGE_ACCOUNT_ACCESS_TIER
  blob_delete_retention_policy_days      = var.blob_delete_retention_policy_days
  container_delete_retention_policy_days = var.container_delete_retention_policy_days
  network_rules_action                   = local.network_rules_action
  add_network                            = var.add_network
  selected_subnet_name                   = var.selected_subnet_name
  selected_network_name                  = var.selected_network_name
  selected_network_rg_name               = var.selected_network_rg_name
  allowed_subnet_ids                     = var.allowed_subnet_ids
  public_network_access_enabled          = local.public_network_access_enabled
  sftp_enabled                           = local.sftp_enabled
  is_hns_enabled                         = local.is_hns_enabled
  APPLICATION_ID                         = var.APPLICATION_ID

  depends_on = [module.rg]
}

# ==============================================================================
# 3. Azure File Shares
# Crée directement sur le SA géré dans ce state (pas de data source).
# ==============================================================================
module "fileshares" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Fileshare?ref=poc"

  storage_account_id = module.storage_account.storage_account_id
  fileshares         = var.fileshares
  APPLICATION_ID     = var.APPLICATION_ID
  quota_gb           = var.quota_gb

  depends_on = [module.storage_account]
}
