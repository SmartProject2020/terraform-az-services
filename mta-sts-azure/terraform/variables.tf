variable "domain" {
  description = "Domaine email à protéger avec MTA-STS (ex: contoso.com)"
  type        = string
}

variable "location" {
  description = "Région Azure pour l'Azure Static Web App"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Nom de l'environnement (ex: prod, staging)"
  type        = string
  default     = "prod"
}

variable "setting" {
  description = "Setting de déploiement : NPR ou PRD"
  type        = string
}


variable "policy_mode" {
  description = "Mode de la stratégie MTA-STS : 'testing' ou 'enforce'"
  type        = string
  default     = "testing"

  validation {
    condition     = contains(["testing", "enforce"], var.policy_mode)
    error_message = "policy_mode doit être 'testing' ou 'enforce'."
  }
}

variable "mx_hosts" {
  description = "Liste des hôtes MX dans la stratégie MTA-STS (Exchange Online par défaut)"
  type        = list(string)
  default     = ["*.mail.protection.outlook.com"]
}

variable "max_age" {
  description = "Durée de cache de la stratégie en secondes"
  type        = number
  default     = 604800
}

variable "policy_id" {
  description = "ID unique de la stratégie MTA-STS (format: YYYYMMDDhh0000). Mettre à jour à chaque changement de stratégie."
  type        = string
}

variable "custom_domain_configured" {
  description = "Passer à true après avoir créé le CNAME DNS mta-sts.<domain> → SWA hostname"
  type        = bool
  default     = false
}

# DNS Azure (optionnel)
variable "azure_dns_zone_resource_group" {
  description = "Resource group de la zone Azure DNS (laisser vide si DNS non géré par Azure)"
  type        = string
  default     = ""
}

variable "azure_dns_zone_name" {
  description = "Nom de la zone Azure DNS (laisser vide si DNS non géré par Azure)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources"
  type        = map(string)
  default     = {}
}
