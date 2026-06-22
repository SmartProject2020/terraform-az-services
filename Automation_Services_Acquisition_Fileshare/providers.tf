# ==============================================================================
# Providers — Automation_Services_Acquisition_Fileshare
#
# Pas de provider hub_subscription : le SA acquisition est toujours public
# (pas de Private Endpoint → pas besoin de résoudre la DNS zone privée).
# ==============================================================================

provider "azurerm" {
  features {}
  storage_use_azuread = true
}
