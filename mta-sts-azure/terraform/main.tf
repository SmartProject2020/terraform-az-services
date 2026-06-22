locals {
  domain_safe     = replace(var.domain, ".", "-")
  env = var.setting == "PRD" ? "PRD" : "DEV"
  resource_prefix = upper ("EM50-${var.setting}-EXCHE-${local.env}-RG01")
  manage_dns      = var.azure_dns_zone_resource_group != "" && var.azure_dns_zone_name != ""
  backup_policy = var.setting == "PRD" ? "PROD" : "NONPROD"
  common_tags = merge(var.tags, {
    Project     = "MTA-STS"
    Domain      = var.domain
    application-id      = "EXCHE"
    backup-policy       = local.backup_policy
    servier-environment = local.env
    ManagedBy   = "Terraform"
  })
}

# ─── Resource Group ───────────────────────────────────────────────────────────

#resource "azurerm_resource_group" "rg" {
#  name     = "${local.resource_prefix}"
#  location = var.location
#  tags     = local.common_tags
#}

# ─── Azure Static Web App ─────────────────────────────────────────────────────

resource "azurerm_static_web_app" "swa" {
  name                = "EM50-PRD-EXCHE-STAPP01"
  resource_group_name = "${local.resource_prefix}"
  location            = "westeurope"
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = local.common_tags
}

# ─── Custom Domain (phase 2 : après création du CNAME DNS) ───────────────────

resource "azurerm_static_web_app_custom_domain" "mta_sts" {
  count = var.custom_domain_configured ? 1 : 0

  static_web_app_id = azurerm_static_web_app.swa.id
  domain_name       = "mta-sts.${var.domain}"
  validation_type   = "cname-delegation"
}

# ─── Azure DNS (optionnel) ────────────────────────────────────────────────────

# CNAME : mta-sts.<domain> → SWA default hostname
resource "azurerm_dns_cname_record" "mta_sts" {
  count = local.manage_dns ? 1 : 0

  name                = "mta-sts"
  zone_name           = var.azure_dns_zone_name
  resource_group_name = var.azure_dns_zone_resource_group
  ttl                 = 3600
  record              = azurerm_static_web_app.swa.default_host_name
}

# TXT : _mta-sts.<domain> → policy ID
resource "azurerm_dns_txt_record" "mta_sts" {
  count = local.manage_dns ? 1 : 0

  name                = "_mta-sts"
  zone_name           = var.azure_dns_zone_name
  resource_group_name = var.azure_dns_zone_resource_group
  ttl                 = 3600

  record {
    value = "v=STSv1; id=${var.policy_id}Z;"
  }
}
