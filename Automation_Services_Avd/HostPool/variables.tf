# ==============================================================================
# Variables generiques (conventions Servier - cf. autres Automation_Services_*)
# ==============================================================================

variable "PLAQUE" {
  description = "Plaque de deploiement (ex: EM50, AM50)"
  type        = string
}

variable "SETTING" {
  description = "Setting NPR ou PRD"
  type        = string
}

variable "APPLICATION_ID" {
  description = "Identifiant de l'application (ex: AVD00) — namespace CMDB de la solution AVD"
  type        = string
}

variable "ENV" {
  description = "Environnement applicatif (ex: DEV, TST, PRD, POC)"
  type        = string
}

variable "RESOURCE_GROUP_INC" {
  description = "Increment du Resource Group dedie au Host Pool (ex: 01, 02)"
  type        = string
  default     = "01"
}

variable "location" {
  description = "Region Azure"
  type        = string
  default     = "France Central"
}

variable "servier_environment" {
  description = "Environnement Servier pour le tag (ex: DEV, PRD)"
  type        = string
}

# ==============================================================================
# Reseau — module Avd/Subnet (1 Host Pool = 1 subnet dedie, HLD section 9)
# ==============================================================================

variable "NETWORK_ZONE" {
  description = "Zone reseau du Host Pool : standard ou critical (choix utilisateur, formulaire ServiceNow v2)"
  type        = string

  validation {
    condition     = contains(["standard", "critical"], var.NETWORK_ZONE)
    error_message = "NETWORK_ZONE doit etre standard ou critical."
  }
}

# ==============================================================================
# Identification du pool — convention HLD v0.1
# Nommage Host Pool : <M|P><PoolID><version>  (ex: MADMSYS1)
# ==============================================================================

variable "POOL_TYPE" {
  description = "Type de pool : M (Multisession / Pooled) ou P (Personnel / Personal)"
  type        = string

  validation {
    condition     = contains(["M", "P"], var.POOL_TYPE)
    error_message = "POOL_TYPE doit etre M (multisession) ou P (personnel)."
  }
}

variable "POOL_ID" {
  description = "Identifiant metier du pool (ex: ADMSYS), utilise dans le nommage Host Pool/Workspace/App Group"
  type        = string
}

variable "POOL_VERSION" {
  description = "Version/increment du pool, utilise comme suffixe numerique des ressources (ex: 1 -> 01)"
  type        = number
  default     = 1
}

# ==============================================================================
# Configuration du Host Pool — section 3 du TAD
# ==============================================================================

variable "friendly_name" {
  description = "Nom convivial affiche aux utilisateurs (ex: Pool Description du formulaire ServiceNow)"
  type        = string
  default     = null
}

variable "description" {
  description = "Description du Host Pool"
  type        = string
  default     = null
}

variable "load_balancer_type" {
  description = "Algorithme de repartition de charge : BreadthFirst, DepthFirst (Pooled) ou Persistent (Personal)"
  type        = string
  default     = "BreadthFirst"
}

variable "personal_desktop_assignment_type" {
  description = "Mode d'attribution pour un pool Personal : Automatic ou Direct (ignore si POOL_TYPE = M)"
  type        = string
  default     = null
}

variable "maximum_sessions_allowed" {
  description = "Nombre maximum de sessions par session host (Pooled uniquement, ignore si POOL_TYPE = P)"
  type        = number
  default     = null
}

variable "start_vm_on_connect" {
  description = "Active le demarrage automatique des session hosts a la connexion utilisateur"
  type        = bool
  default     = true
}

variable "validate_environment" {
  description = "Bascule le Host Pool en environnement de validation"
  type        = bool
  default     = false
}

variable "custom_rdp_properties" {
  description = "Proprietes RDP personnalisees (ex: optimisations RDP ShortPath - section 3.8 du TAD)"
  type        = string
  default     = null
}

variable "registration_expiration_hours" {
  description = "Duree de validite (en heures) du token d'enregistrement des session hosts"
  type        = number
  default     = 8
}

# ==============================================================================
# Stockage FSLogix — 1 Storage Account (Premium FileStorage) + 1 fileshare
# "fslogix" par Host Pool, meme Resource Group. Redondance derivee de ENV.
# ==============================================================================

variable "FSLOGIX_QUOTA_GB" {
  description = "Quota du fileshare fslogix (GB)"
  type        = number
  default     = 100
}

variable "HUB_SUBSCRIPTION_ID" {
  description = "ID de la subscription GL50-HUBCENTRAL hebergeant la Private DNS Zone 'privatelink.file.core.windows.net' (GL50-RG006)"
  type        = string
}

# ==============================================================================
# Key Vault AVD partage (pre-existant, 1 par subscription/env)
# Convention par defaut : ${PLAQUE}-${SETTING}-AVD00-KV01
# Surchargeables si le KV est dans un autre RG ou avec un autre nom.
# ==============================================================================

variable "KV_NAME" {
  description = "Nom du Key Vault AVD partage (pre-existant). Derive par defaut : <PLAQUE>-<SETTING>-AVD00-KV01"
  type        = string
  default     = null
}

variable "KV_RESOURCE_GROUP_NAME" {
  description = "Resource Group du Key Vault AVD. Derive par defaut : <PLAQUE>-<SETTING>-AVD00-<SETTING>-RG01"
  type        = string
  default     = null
}


# ==============================================================================
# ScalingPlan — Personal uniquement (HLD 12.2)
# ==============================================================================

variable "scaling_plan_time_zone" {
  description = "Fuseau horaire du ScalingPlan (Pooled uniquement). Valeurs Windows : ex. 'Romance Standard Time' (Paris), 'UTC'"
  type        = string
  default     = "Romance Standard Time"
}
