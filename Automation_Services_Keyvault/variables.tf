variable "PLAQUE" {
  description = "Plaque de deploiement (ex: EM50, AM50)"
  type        = string
}

variable "SETTING" {
  description = "Setting NPR ou PRD"
  type        = string
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

variable "KEYVAULT_INC" {
  description = "Increment du Key Vault (ex: 01, 02)"
  type        = string
  default     = "01"
}

variable "PE_INC" {
  description = "Increment du PE  (ex: 01, 02)"
  type        = string
  default     = "01"
}

variable "PRIV_ENDPOINT_RESOURCE_TYPE" {
  description = "Sous-ressource cible du Private Endpoint"
  type        = string
  default     = "vault"
}

variable "HUB_SUBSCRIPTION_ID" {
  description = "Subscription HUB hebergeant la Private DNS Zone privatelink.vaultcore.azure.net"
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

variable "subnet_name" {
  description = "Subnet pour le Private Endpoint"
  type        = string
}
variable "vnet_name" {
  description = "VNet pour le Private Endpoint"
  type        = string
}

variable "virtual_network_rg_name" {
  description = "Resource Group du VNet pour le Private Endpoint"
  type        = string
}