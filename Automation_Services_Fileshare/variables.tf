# ==============================================================================
# Variables du root Fileshare
# Inputs minimaux : pas de kind, replication, sftp, etc. (geres par le SA)
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
  description = "Identifiant de l application (utilise comme prefixe des fileshares)"
  type        = string
}

variable "ENV" {
  description = "Environnement applicatif (ex: DEV, TST, PRD)"
  type        = string
}

variable "RESOURCE_GROUP_INC" {
  description = "Increment du Resource Group ou se trouve le SA"
  type        = string
  default     = "01"
}

variable "STORAGE_ACCOUNT_INC" {
  description = "Increment du Storage Account cible"
  type        = string
  default     = "01"
}

variable "SA_EXISTING_RESOURCE_GROUP" {
  description = "RG reel du SA si different de la convention"
  type        = string
  default     = ""
}

variable "fileshares" {
  description = "Liste des noms de fileshares a creer (sans prefixe)"
  type        = set(string)
}

variable "quota_gb" {
  description = "Quota global applique a tous les fileshares (en GB)"
  type        = number
  default     = 100
}
