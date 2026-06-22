# ==============================================================================
# Variables injectees par le pipeline via TF_VAR_*
# ==============================================================================

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

variable "PE_INC" {
  description = "Increment du Private Endpoint (resolu par le pipeline). Si vide, fallback sur STORAGE_ACCOUNT_INC."
  type        = string
  default     = ""
}

variable "STORAGE_ACCOUNT_TYPE" {
  description = "Type d acces reseau : public ou private"
  type        = string

  validation {
    condition     = contains(["public", "private"], var.STORAGE_ACCOUNT_TYPE)
    error_message = "STORAGE_ACCOUNT_TYPE doit etre public ou private."
  }
}

variable "STORAGE_ACCOUNT_TIER" {
  description = "Tier du Storage Account (Standard ou Premium)"
  type        = string

  validation {
    condition     = contains(["Standard", "Premium"], var.STORAGE_ACCOUNT_TIER)
    error_message = "STORAGE_ACCOUNT_TIER doit etre Standard ou Premium."
  }
}

variable "STORAGE_ACCOUNT_KIND" {
  description = "Kind du Storage Account (StorageV2, BlobStorage, FileStorage)"
  type        = string

  validation {
    condition     = contains(["StorageV2", "BlobStorage", "FileStorage"], var.STORAGE_ACCOUNT_KIND)
    error_message = "STORAGE_ACCOUNT_KIND doit etre StorageV2, BlobStorage ou FileStorage."
  }
}

variable "STORAGE_ACCOUNT_REPLICATION_TYPE" {
  description = "Type de replication (LRS, ZRS, GRS)"
  type        = string
}

variable "STORAGE_ACCOUNT_ACCESS_TIER" {
  description = "Tier d acces (Hot ou Cool)"
  type        = string

  validation {
    condition     = contains(["Hot", "Cool"], var.STORAGE_ACCOUNT_ACCESS_TIER)
    error_message = "STORAGE_ACCOUNT_ACCESS_TIER doit etre Hot ou Cool."
  }
}

variable "SFTP_ENABLED" {
  description = "Activer SFTP (StorageV2 uniquement)"
  type        = bool
  default     = false
}

variable "SA_EXISTING_RESOURCE_GROUP" {
  description = "RG reel du SA si different de la convention"
  type        = string
  default     = ""
}

variable "PRIV_ENDPOINT_RESOURCE_TYPE" {
  description = "Sous-ressource cible du Private Endpoint (blob ou file)"
  type        = string
  default     = "blob"
}

variable "HUB_SUBSCRIPTION_ID" {
  description = "Subscription HUB hebergeant la Private DNS Zone"
  type        = string
}

# ==============================================================================
# Variables injectees via tfvars (generees par le pipeline)
# ==============================================================================

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
# Variables reseau
# ==============================================================================

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

variable "add_network" {
  description = "Activer les regles reseau via subnet (deprecie)"
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

variable "delegated_subnet_name" {
  description = "Subnet pour le Private Endpoint"
  type        = string
  default     = ""
}

variable "vnet_name" {
  description = "VNet pour le Private Endpoint"
  type        = string
  default     = ""
}

variable "virtual_network_rg_name" {
  description = "Resource Group du VNet pour le Private Endpoint"
  type        = string
  default     = ""
}
