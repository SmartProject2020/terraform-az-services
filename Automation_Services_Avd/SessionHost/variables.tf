# ------------------------------------------------------------------------------
# Dimensions generiques (alignees sur Automation_Services_Avd_HostPool)
# ------------------------------------------------------------------------------
variable "PLAQUE" {
  description = "Plaque (EM50, AM50, AP50, GL50)"
  type        = string
}

variable "SETTING" {
  description = "Setting (NPR, PRD)"
  type        = string
}

variable "APPLICATION_ID" {
  description = "Identifiant applicatif (namespace AVD, ex: AVD00)"
  type        = string
}

variable "ENV" {
  description = "Environnement applicatif"
  type        = string
}

variable "servier_environment" {
  description = "Servier Environment (tag)"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "France Central"
}

# ------------------------------------------------------------------------------
# Reference au Host Pool existant — sert a localiser son Resource Group, son
# nom et son registration_token via terraform_remote_state (cf. locals.tf).
# Seul l'identifiant metier du pool (HOST_POOL_ID) est necessaire : PLAQUE,
# ENV et APPLICATION_ID sont partages avec le Host Pool qui porte ces hosts.
# ------------------------------------------------------------------------------
variable "HOST_POOL_NAME" {
  description = "Nom complet du Host Pool cible (ex: MADMSYS1)"
  type        = string
}

# Coordonnees du state distant du Host Pool — recopiees par le workflow depuis
# backends/${PLAQUE}-${ENV}.tfbackend DE CE MODULE (meme storage account/
# container que ce module, seul le "key" differe : "avd-hostpool-tfstate").
# Evite de redupliquer la convention de nommage des comptes de stockage d'etat.
variable "tfstate_resource_group_name" {
  description = "Resource Group du storage account de tfstate (= valeur du backend de ce module)"
  type        = string
}

variable "tfstate_storage_account_name" {
  description = "Storage account de tfstate (= valeur du backend de ce module)"
  type        = string
}

variable "tfstate_container_name" {
  description = "Container de tfstate (= valeur du backend de ce module)"
  type        = string
}

# ------------------------------------------------------------------------------
# Identification / nommage des Session Hosts — TAD section 2.2
# ------------------------------------------------------------------------------
variable "start_index" {
  description = "Numero incremental de depart (permet d'ajouter des hosts sans recreer les existants)"
  type        = number
  default     = 1
}

# ------------------------------------------------------------------------------
# Dimensionnement (CR workshop, cf. memoire architecture v2) — vm_size et
# session_host_count sont DERIVES (locals.tf) de POOL_TYPE + WORKLOAD_TYPE/
# USER_COUNT (Personal) ou USER_TIER/vm_count_override (MultiSession).
# ------------------------------------------------------------------------------
variable "POOL_TYPE" {
  description = "Type de pool : M (Multisession/Pooled) ou P (Personnel/Personal) — determine la table de sizing utilisee"
  type        = string

  validation {
    condition     = contains(["M", "P"], var.POOL_TYPE)
    error_message = "POOL_TYPE doit etre M (multisession) ou P (personnel)."
  }
}

variable "WORKLOAD_TYPE" {
  description = "Type de charge de travail (pools Personal uniquement) : Light, Standard, Standard+Teams, Heavy, Power -> determine vm_size"
  type        = string
  default     = null
}

variable "USER_COUNT" {
  description = "Nombre d'utilisateurs (pools Personal uniquement) : 1 utilisateur = 1 Session Host -> determine session_host_count"
  type        = number
  default     = null
}

variable "USER_TIER" {
  description = "Palier d'utilisateurs (pools MultiSession uniquement) : 0-10, 10-30, 30-50, 50-100, 100-250, 250+ -> determine vm_size et session_host_count"
  type        = string
  default     = null
}

variable "vm_count_override" {
  description = "Nombre de Session Hosts force (pools MultiSession uniquement, paliers 50-100/100-250/250+ sans valeur fixe arretee) — remplace la valeur par defaut du palier"
  type        = number
  default     = null
}

# ------------------------------------------------------------------------------
# Configuration machine virtuelle
# ------------------------------------------------------------------------------
variable "admin_username" {
  description = "Nom d'utilisateur administrateur local"
  type        = string
}

variable "os_disk_type" {
  description = "Type de disque managed (storage_account_type) du disque OS"
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "Taille du disque OS en GiB"
  type        = number
  default     = 128
}

variable "image_publisher" {
  description = "Publisher de l'image marketplace (surcharge le defaut derive de POOL_TYPE, cf. locals.tf)"
  type        = string
  default     = null
}

variable "image_offer" {
  description = "Offre de l'image marketplace (surcharge le defaut derive de POOL_TYPE, cf. locals.tf)"
  type        = string
  default     = null
}

variable "image_sku" {
  description = "SKU de l'image marketplace (surcharge le defaut derive de POOL_TYPE, cf. locals.tf)"
  type        = string
  default     = null
}

variable "image_version" {
  description = "Version de l'image marketplace (surcharge le defaut derive de POOL_TYPE, cf. locals.tf)"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Identite + agent AVD
# ------------------------------------------------------------------------------
variable "entra_id_join" {
  description = "Jonction Microsoft Entra ID (TAD 3.3 'Entra ID uniquement ?')"
  type        = bool
  default     = true
}

variable "intune_enrollment_enabled" {
  description = "Declenche l'enrollment MDM Intune (mdmId) a la jonction Entra ID — TAD section 7, Intune exclusif pour Windows 11"
  type        = bool
  default     = true
}

variable "avd_agent_package_url" {
  description = "URL du package DSC contenant l'agent AVD (Configuration.zip) — fourni via vars.AVD_AGENT_PACKAGE_URL"
  type        = string
}
