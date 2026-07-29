terraform {
  backend "azurerm" {
    use_oidc = true
  }

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "= 4.75.0"
      configuration_aliases = [azurerm.hub_subscription]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0.0"
    }
  }

  required_version = ">= 1.3.0"
}
