

module "rg" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//ResourceGroup?ref=poc"

  name                = local.rg_name
  location            = var.location
  application_id      = var.APPLICATION_ID
  backup_policy       = local.backup_policy
  servier_environment = var.servier_environment
}

module "keyvault" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Keyvault?ref=poc"

  keyvault_name       = local.kv_name
  resource_group_name = local.rg_name
  APPLICATION_ID      = var.APPLICATION_ID
  SETTING             = var.SETTING
  servier_environment = var.servier_environment
  backup_policy       = local.backup_policy

  depends_on = [module.rg]

}

module "private_endpoint" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//PrivateEndpoint?ref=poc"

  resource_group_name      = local.rg_name
  resource_group_name_vnet = var.virtual_network_rg_name
  network_name             = var.vnet_name
  subnet_name              = var.subnet_name
  endpoint_name            = local.pe_name
  connection_resource_id   = module.keyvault.keyvault_id
  resource_type            = var.PRIV_ENDPOINT_RESOURCE_TYPE

  # La zone DNS privatelink.vaultcore.azure.net est hebergee dans la
  # subscription HUB (GL50-HUBCENTRAL) et non dans la subscription workload.
  # Le provider hub_subscription est necessaire pour que le data source
  # azurerm_private_dns_zone puisse la resoudre.
  providers = {
    azurerm.hub_subscription = azurerm.hub_subscription
  }

  depends_on = [module.keyvault]
}