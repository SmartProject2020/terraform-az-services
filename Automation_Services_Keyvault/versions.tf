terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 3.53.0"
      configuration_aliases = [azurerm.hub_subscription]
    }
  }
  required_version = ">= 1.3.0"
}