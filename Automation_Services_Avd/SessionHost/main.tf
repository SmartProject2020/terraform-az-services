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

data "azurerm_resource_group" "vnet_rg" {
  name = local.vnet_rg_name
}

module "session_host" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Avd/SessionHost?ref=poc"

  resource_group_name = local.resource_group_name
  location            = data.azurerm_resource_group.vnet_rg.location

  name_prefix        = local.name_prefix
  session_host_count = local.session_host_count
  start_index        = var.start_index

  vm_size        = local.vm_size
  admin_username = local.admin_username
  admin_password = data.azurerm_key_vault_secret.admin.value

  subnet_id       = local.subnet_id
  zones           = local.zones
  os_disk_type    = var.os_disk_type
  os_disk_size_gb = var.os_disk_size_gb

  source_image_reference = {
    publisher = local.image_publisher
    offer     = local.image_offer
    sku       = local.image_sku
    version   = local.image_version
  }

  entra_id_join             = var.entra_id_join
  intune_enrollment_enabled = var.intune_enrollment_enabled
  host_pool_name            = local.host_pool_name
  registration_token        = local.registration_token
  avd_agent_package_url     = var.avd_agent_package_url

  fslogix_enabled                                    = var.fslogix_enabled
  fslogix_vhd_locations                              = local.fslogix_vhd_locations
  fslogix_size_in_mb                                 = var.fslogix_size_in_mb
  fslogix_volume_type                                = var.fslogix_volume_type
  fslogix_is_dynamic                                 = var.fslogix_is_dynamic
  fslogix_flip_flop_profile_directory_name           = var.fslogix_flip_flop_profile_directory_name
  fslogix_delete_local_profile_when_vhd_should_apply = var.fslogix_delete_local_profile_when_vhd_should_apply
  fslogix_access_network_as_computer_object          = var.fslogix_access_network_as_computer_object
  fslogix_keep_local_dir                             = var.fslogix_keep_local_dir
  fslogix_prevent_login_with_failure                 = var.fslogix_prevent_login_with_failure
  fslogix_roam_identity                              = var.fslogix_roam_identity
  fslogix_roam_search                                = var.fslogix_roam_search
  fslogix_no_profile_containing_folder               = var.fslogix_no_profile_containing_folder
  fslogix_vhd_name_match                             = var.fslogix_vhd_name_match
  fslogix_vhd_name_pattern                           = var.fslogix_vhd_name_pattern
  fslogix_logging_enabled                            = var.fslogix_logging_enabled
  fslogix_logging_level                              = var.fslogix_logging_level

  APPLICATION_ID      = var.APPLICATION_ID
  servier_environment = var.servier_environment
  backup_policy       = local.backup_policy
}
