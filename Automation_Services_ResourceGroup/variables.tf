# ==============================================================================
# Variables injectées par le pipeline via TF_VAR_*
# ==============================================================================

variable "PLAQUE" {
  description = "Plaque de déploiement (ex: EM50, AM50)"
  type        = string
}

variable "SETTING" {
  description = "Setting de déploiement : NPR, POC ou PRD"
  type        = string

  validation {
    condition     = contains(["NPR", "POC", "PRD"], var.SETTING)
    error_message = "SETTING doit être NPR, POC ou PRD."
  }
}

variable "APPLICATION_ID" {
  description = "Identifiant de l'application"
  type        = string
}

variable "ENV" {
  description = "Environnement applicatif (ex: DEV, TST, PRD)"
  type        = string
}

variable "resource_group_inc" {
  description = "Incrément du Resource Group (ex: 01, 02)"
  type        = string
  default     = "01"
}

# ==============================================================================
# Variables injectées via tfvars (générées par le pipeline)
# ==============================================================================

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "France Central"
}

variable "servier_environment" {
  description = "Environnement Servier pour le tag (ex: DEV, PRD)"
  type        = string
}
