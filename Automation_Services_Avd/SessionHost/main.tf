# ==============================================================================
# Root module : Automation_Services_Avd_SessionHost
# Gere : Session Hosts (VM Windows) rattaches a un Host Pool AVD existant
#
# Le Host Pool est gere par un module/workflow distinct (Automation_Services_
# Avd_HostPool). On lit son Resource Group, son nom et son registration_token
# via terraform_remote_state — les Session Hosts sont deployes dans le MEME
# Resource Group que leur Host Pool (suivi de cout par pool — TAD section 1.1).
#
# Coordonnees du state distant (resource_group_name / storage_account_name /
# container_name) = CELLES DU FICHIER backends/${PLAQUE}-${ENV}.tfbackend DE CE
# MEME MODULE (passees en TF_VAR_tfstate_* par le workflow) : tous les modules
# racines d'une meme combinaison PLAQUE/SETTING/ENV partagent le meme storage
# account / container — seul le "key" differe (ici "avd-hostpool-tfstate").
# On reutilise donc la source de verite existante plutot que de redupliquer la
# convention de nommage.
# ==============================================================================

data "terraform_remote_state" "host_pool" {
  backend   = "azurerm"
  workspace = local.host_pool_workspace

  config = {
    resource_group_name  = var.tfstate_resource_group_name
    storage_account_name = var.tfstate_storage_account_name
    container_name       = var.tfstate_container_name
    key                  = "avd-hostpool-tfstate"
  }
}

data "azurerm_key_vault_secret" "admin" {
  name         = "avdlocaladmin-${local.host_pool_name}"
  key_vault_id = data.terraform_remote_state.host_pool.outputs.kv_id
}

module "session_host" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Avd/SessionHost?ref=poc"

  resource_group_name = local.resource_group_name
  location            = var.location

  name_prefix        = local.name_prefix
  session_host_count = local.session_host_count
  start_index        = var.start_index

  vm_size        = local.vm_size
  admin_username = var.admin_username
  admin_password = data.azurerm_key_vault_secret.admin.value

  subnet_id    = local.subnet_id
  zones        = local.zones
  os_disk_type = var.os_disk_type

  source_image_reference = {
    publisher = "MicrosoftWindowsDesktop"
    offer     = var.image_offer
    sku       = var.image_sku
    version   = "latest"
  }

  entra_id_join         = var.entra_id_join
  host_pool_name        = local.host_pool_name
  registration_token    = local.registration_token
  avd_agent_package_url = var.avd_agent_package_url

  APPLICATION_ID      = var.APPLICATION_ID
  servier_environment = var.servier_environment
  backup_policy       = local.backup_policy
}
