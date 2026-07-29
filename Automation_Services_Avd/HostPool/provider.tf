provider "azurerm" {
  features {}
  storage_use_azuread = true
}

provider "azurerm" {
  alias           = "hub_subscription"
  subscription_id = var.HUB_SUBSCRIPTION_ID
  features {}
}

# ScalingPlan Personal (hostPoolType=Personal + personalSchedules) n'est pas
# expose par azurerm_virtual_desktop_scaling_plan (hostPoolType fige a "Pooled"
# cote provider) -> gere en appel ARM direct via azapi.
provider "azapi" {}
