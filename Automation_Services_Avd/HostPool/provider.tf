provider "azurerm" {
  features {}
  storage_use_azuread = true
}

provider "azurerm" {
  alias           = "hub_subscription"
  subscription_id = var.HUB_SUBSCRIPTION_ID
  features {}
}
