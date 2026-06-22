output "swa_default_hostname" {
  description = "Hostname par défaut du Static Web App (à utiliser pour le CNAME DNS)"
  value       = azurerm_static_web_app.swa.default_host_name
}

output "swa_deployment_token" {
  description = "Token de déploiement SWA (à enregistrer comme secret GitHub AZURE_SWA_DEPLOYMENT_TOKEN)"
  value       = azurerm_static_web_app.swa.api_key
  sensitive   = true
}

output "mta_sts_policy_url" {
  description = "URL de la stratégie MTA-STS (disponible après configuration du domaine personnalisé)"
  value       = "https://mta-sts.${var.domain}/.well-known/mta-sts.txt"
}

output "dns_records_to_create" {
  description = "Enregistrements DNS à créer manuellement (si DNS non géré par Azure)"
  value = var.azure_dns_zone_resource_group == "" ? {
    cname = {
      type  = "CNAME"
      name  = "mta-sts.${var.domain}"
      value = azurerm_static_web_app.swa.default_host_name
      ttl   = 3600
    }
    txt = {
      type  = "TXT"
      name  = "_mta-sts.${var.domain}"
      value = "v=STSv1; id=${var.policy_id}Z;"
      ttl   = 3600
    }
  } : null
}
