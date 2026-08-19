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
  default     = "AVD00"
}

variable "ENV" {
  description = "Environnement applicatif (ex: DEV, TST, PRD, POC)"
  type        = string
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
  description = "Identifiant metier du pool incluant son increment (ex: ADMSYS1, ADMSYS2), utilise dans le nommage Host Pool/Workspace/App Group"
  type        = string
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
  default     = "DepthFirst"
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
  description = "Proprietes RDP personnalisees (ex: optimisations RDP ShortPath - section 3.8 du TAD). Le workflow fournit deja un defaut standard Servier si l'input n'est pas renseigne (cf. terraform-avd-hostpool.yml) ; ce defaut ici sert pour un usage direct hors workflow (smoke test, etc.)."
  type        = string
  default     = "enablecredsspsupport:i:1;enablerdsaadauth:i:1;autoreconnection enabled:i:1;bandwidthautodetect:i:1;networkautodetect:i:1;videoplaybackmode:i:1;audiocapturemode:i:1;encode redirected video capture:i:1;audiomode:i:0;camerastoredirect:s:*;devicestoredirect:s:*;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:1;redirectprinters:i:0;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:;use multimon:i:1;maximizetocurrentdisplays:i:0;singlemoninwindowedmode:i:1;screen mode id:i:1;smart sizing:i:1;dynamic resolution:i:1;"
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

variable "NB_USERS" {
  description = "Nombre d'utilisateurs du pool — sert a calculer le quota FSLogix (NB_USERS * 5 Go, minimum 100 Go)"
  type        = number
}

variable "HUB_SUBSCRIPTION_ID" {
  description = "ID de la subscription GL50-HUBCENTRAL hebergeant la Private DNS Zone 'privatelink.file.core.windows.net' (GL50-RG006)"
  type        = string
}

variable "sa_public_network_access_enabled" {
  description = "Acces public du Storage Account FSLogix. Le runner self-hosted n'a pas de route reseau vers le Private Endpoint sur certains subnets AVD (constate sur PADMSS4, 2026-08-12) — acces public laisse actif pour eviter le contournement bootstrap."
  type        = bool
  default     = true
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