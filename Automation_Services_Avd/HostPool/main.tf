# ==============================================================================
# Root module : Automation_Services_Avd_HostPool
# Gere : Host Pool AVD (+ token d'enregistrement) dans un Resource Group pre-existant
#
# Le Resource Group n'est pas gere ici — il est lu via data source.
# Cela permet de deployer le Host Pool dans n'importe quelle region Azure
# independamment de la region du Resource Group.
# ==============================================================================

data "azurerm_resource_group" "rg" {
  name = local.rg_name
}

module "host_pool" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Avd/HostPool?ref=poc"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  name                = local.host_pool_name

  type               = local.avd_type
  load_balancer_type = var.load_balancer_type

  personal_desktop_assignment_type = var.personal_desktop_assignment_type
  maximum_sessions_allowed         = var.maximum_sessions_allowed

  friendly_name         = var.friendly_name
  description           = var.description
  start_vm_on_connect   = var.start_vm_on_connect
  validate_environment  = var.validate_environment
  custom_rdp_properties = var.custom_rdp_properties

  registration_expiration_hours = var.registration_expiration_hours

  APPLICATION_ID      = var.APPLICATION_ID
  servier_environment = var.servier_environment
  backup_policy       = local.backup_policy
}

# Subnet dedie au Host Pool (1 Host Pool = 1 subnet, HLD section 9) + NSG
# "flux standard" (HLD section 9.5.1). VNET et RG cibles determines via la
# table de correspondance SETTING+NETWORK_ZONE (local.network).
module "subnet" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Avd/Subnet?ref=poc"

  resource_group_name  = local.network.resource_group_name
  virtual_network_name = local.network.virtual_network_name
  vnet_address_space   = local.network.vnet_address_space
  newbits              = local.network.newbits

  subnet_name = local.subnet_name
  nsg_name    = local.nsg_name
  location    = var.location

  tags = local.common_tags
}

# Stockage FSLogix : 1 Storage Account (Premium FileStorage) + 1 fileshare
# "fslogix" par Host Pool, dans le meme Resource Group. Redondance derivee de
# l environnement (local.storage_redundancy).
module "storage_account" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//StorageAccount?ref=poc"

  resource_group_name              = data.azurerm_resource_group.rg.name
  storage_account_name             = local.storage_account_name
  storage_account_tier             = "Premium"
  storage_account_kind             = "FileStorage"
  storage_account_replication_type = local.storage_redundancy

  servier_environment = var.servier_environment
  APPLICATION_ID      = var.APPLICATION_ID
}

module "fileshare" {
  source = "git::https://github.com/SmartProject2020/terraform-az-modules.git//Fileshare?ref=poc"

  storage_account_id = module.storage_account.storage_account_id
  fileshares         = ["fslogix"]
  APPLICATION_ID     = var.APPLICATION_ID
  quota_gb           = var.FSLOGIX_QUOTA_GB
}

# ==============================================================================
# Mot de passe administrateur local — genere une fois a la creation du pool,
# stocke dans le Key Vault AVD partage. Lu par Automation_Services_Avd_SessionHost
# via terraform_remote_state (outputs.kv_id).
#
# Import sur un pool existant (step 8b du workflow) :
#   random_password.admin      -> terraform import ... ",$PASSWORD_VALUE"
#   azurerm_key_vault_secret.admin -> terraform import ... "<KV_ID>/secrets/<SECRET_NAME>"
# ==============================================================================

data "azurerm_key_vault" "avd" {
  name                = local.kv_name
  resource_group_name = local.kv_resource_group_name
}

resource "random_password" "admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "azurerm_key_vault_secret" "admin" {
  name         = "avdlocaladmin-${local.host_pool_name}"
  value        = random_password.admin.result
  key_vault_id = data.azurerm_key_vault.avd.id
  content_type = "text/plain"
}

# ==============================================================================
# Task #6 — Groupes Entra ID + RBAC par pool
#
# Les SPs Microsoft AVD sont identifies par leur App ID (fixe, identique dans
# tous les tenants) — le provider azuread resout l'Object ID tenant-specifique.
#
# Role non attribue ici : Desktop Virtualization User sur AppGroup
# -> defere a Task #7 (AppGroup cree dans Automation_Services_Avd_Workspace)
# ==============================================================================

resource "azuread_group" "users" {
  display_name     = "CB-GO-AVD${local.host_pool_name}-USERS"
  mail_nickname    = "cb-go-avd${lower(local.host_pool_name)}-users"
  security_enabled = true
}

resource "azurerm_role_assignment" "vm_user_login" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = azuread_group.users.object_id
}

resource "azurerm_role_assignment" "smb_contributor" {
  scope                = module.storage_account.storage_account_id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azuread_group.users.object_id
}

# Desktop Virtualization Power On Off Contributor pour AVD SP et WVD ARM Provider SP :
# assignment manuel one-shot au niveau subscription (couvre tous les pools).
# az role assignment create --role "Desktop Virtualization Power On Off Contributor" \
#   --assignee "9cdead84-a844-4324-93f2-b2e6bb768d07" --scope "/subscriptions/<SUB_ID>"
# az role assignment create --role "Desktop Virtualization Power On Off Contributor" \
#   --assignee "50e95039-b200-4007-bc97-8d5790743a63" --scope "/subscriptions/<SUB_ID>"

# ==============================================================================
# Task #7 — AppGroup + Workspace + ScalingPlan (Personal uniquement)
#
# Nommage HLD :
#   App Group   : <POOL_NAME>-DAG  (ex: MTEST1-DAG)
#   Workspace   : <POOL_NAME>      (ex: MTEST1) — 1 workspace par pool
#   Scaling Plan: <POOL_NAME>-SP   — Personal uniquement (HLD 12.2)
#                 MultiSession = taille statique, pas de ScalingPlan
# ==============================================================================

resource "azurerm_virtual_desktop_application_group" "dag" {
  name                = "${local.host_pool_name}-DAG"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  host_pool_id        = module.host_pool.host_pool_id
  type                = "Desktop"

  tags = local.common_tags
}

resource "azurerm_virtual_desktop_workspace" "ws" {
  name                = local.host_pool_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  tags = local.common_tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "ws_dag" {
  workspace_id         = azurerm_virtual_desktop_workspace.ws.id
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
}

resource "azurerm_role_assignment" "dvd_user" {
  scope                = azurerm_virtual_desktop_application_group.dag.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = azuread_group.users.object_id
}

resource "azurerm_virtual_desktop_scaling_plan" "sp" {
  count               = local.avd_type == "Pooled" ? 1 : 0
  name                = "${local.host_pool_name}-SP"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  time_zone           = var.scaling_plan_time_zone

  host_pool {
    hostpool_id          = module.host_pool.host_pool_id
    scaling_plan_enabled = true
  }

  schedule {
    name                                     = "Semaine"
    days_of_week                             = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                       = "07:30"
    ramp_up_load_balancing_algorithm         = "BreadthFirst"
    ramp_up_capacity_threshold_percent       = 60
    peak_start_time                          = "08:00"
    peak_load_balancing_algorithm            = "BreadthFirst"
    ramp_down_start_time                     = "18:00"
    ramp_down_load_balancing_algorithm       = "BreadthFirst"
    ramp_down_minimum_hosts_percent          = 0
    ramp_down_capacity_threshold_percent     = 90
    ramp_down_force_logoff_users             = false
    ramp_down_wait_time_minutes              = 30
    ramp_down_notification_message           = "Votre session va etre fermee dans 30 minutes. Veuillez enregistrer votre travail."
    ramp_down_stop_hosts_when                = "ZeroActiveSessions"
    off_peak_start_time                      = "20:00"
    off_peak_load_balancing_algorithm        = "BreadthFirst"
  }

  tags = local.common_tags
}
