# ==============================================================================
# Variables — Automation_Services_Acquisition_Fileshare
# Alignées sur la convention Automation_Services_Storageaccount
# ==============================================================================

# ── Identifiants ressources ───────────────────────────────────────────────────
variable "PLAQUE" {
  description = "Plaque de deploiement (ex: EM50, AM50)"
  type        = string
}

variable "SETTING" {
  description = "Setting de deploiement : NPR, POC ou PRD"
  type        = string

  validation {
    condition     = contains(["NPR", "POC", "PRD"], var.SETTING)
    error_message = "SETTING doit etre NPR, POC ou PRD."
  }
}

variable "APPLICATION_ID" {
  description = "Identifiant de l application"
  type        = string
}

variable "ENV" {
  description = "Environnement applicatif (ex: DEV, TST, PRD)"
  type        = string
}

variable "RESOURCE_GROUP_INC" {
  description = "Increment du Resource Group (ex: 01, 02)"
  type        = string
  default     = "01"
}

variable "STORAGE_ACCOUNT_INC" {
  description = "Increment du Storage Account (ex: 01, 02)"
  type        = string
  default     = "01"
}

# ── Configuration Storage Account ────────────────────────────────────────────
variable "STORAGE_ACCOUNT_TIER" {
  description = "Tier du Storage Account (Standard ou Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.STORAGE_ACCOUNT_TIER)
    error_message = "STORAGE_ACCOUNT_TIER doit etre Standard ou Premium."
  }
}

variable "STORAGE_ACCOUNT_KIND" {
  description = "Kind du Storage Account — toujours FileStorage pour l acquisition"
  type        = string
  default     = "FileStorage"

  validation {
    condition     = contains(["StorageV2", "BlobStorage", "FileStorage"], var.STORAGE_ACCOUNT_KIND)
    error_message = "STORAGE_ACCOUNT_KIND doit etre StorageV2, BlobStorage ou FileStorage."
  }
}

variable "STORAGE_ACCOUNT_REPLICATION_TYPE" {
  description = "Type de replication (LRS ou ZRS pour FileStorage)"
  type        = string
  default     = "LRS"
}

variable "STORAGE_ACCOUNT_ACCESS_TIER" {
  description = "Tier d acces (Hot ou Cool)"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.STORAGE_ACCOUNT_ACCESS_TIER)
    error_message = "STORAGE_ACCOUNT_ACCESS_TIER doit etre Hot ou Cool."
  }
}

# ── Rétention ─────────────────────────────────────────────────────────────────
variable "blob_delete_retention_policy_days" {
  description = "Retention des blobs supprimes (jours)"
  type        = number
  default     = 7
}

variable "container_delete_retention_policy_days" {
  description = "Retention des containers supprimes (jours)"
  type        = number
  default     = 7
}

# ── Réseau (legacy — non utilisé en mode acquisition public) ─────────────────
variable "add_network" {
  description = "Activer les regles reseau via subnet (non utilise en mode public)"
  type        = bool
  default     = false
}

variable "allowed_subnet_ids" {
  description = "Liste des Subnet IDs autorises"
  type        = list(string)
  default     = []
}

variable "selected_network_name" {
  type    = string
  default = ""
}

variable "selected_subnet_name" {
  type    = string
  default = ""
}

variable "selected_network_rg_name" {
  type    = string
  default = ""
}

# ── Azure / Servier ───────────────────────────────────────────────────────────
variable "location" {
  description = "Region Azure"
  type        = string
  default     = "France Central"
}

variable "servier_environment" {
  description = "Environnement Servier pour le tag (ex: DEV, PRD)"
  type        = string
}

# ── Fileshares ────────────────────────────────────────────────────────────────
variable "fileshares" {
  description = "Liste des noms de fileshares a creer"
  type        = list(string)
}

variable "quota_gb" {
  description = "Quota en GB par fileshare"
  type        = number
  default     = 100
}

# ── Microsoft Defender for Storage ───────────────────────────────────────────
variable "enable_defender" {
  description = "Activer Microsoft Defender for Storage (recommande pour l acquisition : fichiers provenant d entites externes)"
  type        = bool
  default     = true
}

variable "defender_malware_scanning_enabled" {
  description = "Activer le scan malware a l upload des fichiers"
  type        = bool
  default     = true
}

variable "defender_malware_scanning_cap_gb_per_month" {
  description = "Plafond mensuel de scan malware en GB (-1 = illimite)"
  type        = number
  default     = 5000
}

variable "defender_sensitive_data_discovery_enabled" {
  description = "Activer la detection de donnees sensibles (PII, secrets)"
  type        = bool
  default     = true
}
