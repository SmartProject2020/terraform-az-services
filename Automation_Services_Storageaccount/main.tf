# ==============================================================================
# Root module : Automation_Services_Storageaccount
# Gere : Resource Group + Storage Account + Private Endpoint
# Les fileshares sont geres par Automation_Services_Fileshare (workflow separe).
# ==============================================================================

module "rg" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//ResourceGroup?ref=poc"

  name                = local.rg_name
  location            = var.location
  application_id      = var.APPLICATION_ID
  backup_policy       = local.backup_policy
  servier_environment = var.servier_environment
}

module "storage_account" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//StorageAccount?ref=poc"

  resource_group_name                    = local.sa_resource_group_name
  location                               = var.location
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
  servier_environment                    = var.servier_environment
  APPLICATION_ID                         = var.APPLICATION_ID
  
  depends_on = [module.rg]
}

module "private_endpoint" {
  count = var.STORAGE_ACCOUNT_TYPE == "private" ? 1 : 0

  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//PrivateEndpoint?ref=poc"

  resource_group_name      = local.sa_resource_group_name
  location                 = var.location
  resource_group_name_vnet = var.virtual_network_rg_name
  network_name             = var.vnet_name
  subnet_name              = var.delegated_subnet_name
  endpoint_name            = local.endpoint_name
  connection_resource_id   = module.storage_account.storage_account_id
  resource_type            = var.PRIV_ENDPOINT_RESOURCE_TYPE

  providers = {
    azurerm.hub_subscription = azurerm.hub_subscription
  }

  depends_on = [module.storage_account]
}
