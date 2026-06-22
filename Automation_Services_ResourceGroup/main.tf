
module "rg" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//ResourceGroup?ref=poc"
  name                = local.rg_name
  location            = var.location
  application_id      = var.APPLICATION_ID
  backup_policy       = local.backup_policy
  servier_environment = var.servier_environment
}
