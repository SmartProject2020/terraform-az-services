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
  default     = "AVD00"
}

variable "ENV" {
  description = "Environnement applicatif"
  type        = string
}

variable "servier_environment" {
  description = "Servier Environment (tag)"
  type        = string
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
  description = "Nombre TOTAL de Session Hosts force pour le pool — remplace la valeur derivee du palier (MultiSession, paliers 50-100/100-250/250+) ou de USER_COUNT (Personal). ATTENTION : session_host_count est un TOTAL, pas un delta ; pour ajouter/retirer des hosts sur un pool existant sans toucher aux VM en place, garder start_index a sa valeur d'origine et n'ajuster que ce total (cf. incident PADMSS6 du 2026-08-14 : USER_COUNT=2 seul avait ecrase le total et detruit les VM au-dela de l'index 1)."
  type        = number
  default     = null
}

variable "vm_size_override" {
  description = "Force vm_size (contournement quota ponctuel sur un environnement de test) — remplace le sizing derive de POOL_TYPE/WORKLOAD_TYPE/USER_TIER"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Configuration machine virtuelle
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# FSLogix — Profile Containers (learn.microsoft.com/fslogix/reference-configuration-settings)
# VHDLocations est toujours derive du fileshare du Host Pool (locals.tf) —
# seuls les reglages de dimensionnement/comportement sont surchargeables ici.
# ------------------------------------------------------------------------------
variable "fslogix_enabled" {
  description = "Installe et active FSLogix Profile Containers sur les Session Hosts"
  type        = bool
  default     = true
}

variable "fslogix_size_in_mb" {
  description = "Taille max du VHD(x) de profil par utilisateur, en Mo"
  type        = number
  default     = 30000
}

variable "fslogix_volume_type" {
  description = "Format du conteneur de profil (vhd ou vhdx)"
  type        = string
  default     = "vhdx"
}

variable "fslogix_is_dynamic" {
  description = "VHD(x) dynamique (n'occupe que l'espace reellement utilise)"
  type        = bool
  default     = true
}

variable "fslogix_flip_flop_profile_directory_name" {
  description = "Nomme le dossier de profil <username>_<sid> au lieu de <sid>_<username>. SANS EFFET quand fslogix_no_profile_containing_folder=true — laisse au defaut (false)."
  type        = bool
  default     = false
}

variable "fslogix_delete_local_profile_when_vhd_should_apply" {
  description = "Supprime le profil Windows local existant quand FSLogix doit s'appliquer (recommandation Microsoft AVD)"
  type        = bool
  default     = true
}

variable "fslogix_access_network_as_computer_object" {
  description = "Attache le VHD(x) en tant qu'objet ordinateur au lieu de l'utilisateur"
  type        = bool
  default     = false
}

variable "fslogix_keep_local_dir" {
  description = "Conserve le dossier local_%username% apres deconnexion"
  type        = bool
  default     = true
}

variable "fslogix_prevent_login_with_failure" {
  description = "Bloque la connexion si l'attachement au VHD(x) de profil echoue"
  type        = bool
  default     = true
}

variable "fslogix_roam_identity" {
  description = "Roaming legacy des donnees d'identite — Microsoft deconseille ce reglage sur postes Intune/Entra ID joints, laisse au defaut recommande (false)"
  type        = bool
  default     = false
}

variable "fslogix_roam_search" {
  description = "Roaming de la base de recherche Windows (0=off, 1=mono-utilisateur, 2=multi-utilisateur)"
  type        = number
  default     = 0
}

variable "fslogix_no_profile_containing_folder" {
  description = "Le conteneur de profil n'utilise pas de sous-dossier par SID — prioritaire sur fslogix_flip_flop_profile_directory_name"
  type        = bool
  default     = true
}

variable "fslogix_vhd_name_match" {
  description = "Motif de recherche du fichier VHD(x) de profil existant"
  type        = string
  default     = "%username%"
}

variable "fslogix_vhd_name_pattern" {
  description = "Motif de creation du fichier VHD(x) de profil — doit correspondre a fslogix_vhd_name_match"
  type        = string
  default     = "%username%"
}

variable "fslogix_logging_enabled" {
  description = "Niveau d'activation des logs FSLogix (0=off, 1=logs par composant, 2=tous les logs)"
  type        = number
  default     = 2
}

variable "fslogix_logging_level" {
  description = "Verbosite des logs FSLogix (0=Verbose, 1=Standard, 2=Minimal, 3=Erreurs uniquement)"
  type        = number
  default     = 1
}
