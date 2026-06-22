# ==============================================================================
# Cree uniquement les Azure File Shares sur un SA EXISTANT.
# Le SA doit avoir ete cree au prealable via Automation_Services_Storageaccount.
# Le SA est reference via data source : il n est pas dans le state Fileshare.

# ==============================================================================
# Data source : lecture seule du SA existant
# Si le SA n existe pas -> Terraform retourne une erreur claire.
# ==============================================================================
data "azurerm_storage_account" "sa" {
  name                = local.storage_account_name
  resource_group_name = local.sa_resource_group_name
}

# ==============================================================================
# Creation des fileshares sur le SA existant
# ==============================================================================
module "fileshares" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Fileshare?ref=poc"

  storage_account_id = data.azurerm_storage_account.sa.id
  fileshares         = var.fileshares
  APPLICATION_ID     = var.APPLICATION_ID
  quota_gb           = var.quota_gb
}