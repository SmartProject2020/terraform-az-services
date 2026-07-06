# Repo root   : SmartProject2020/Azure_Terraform_Services (branch: poc)
# Repo module : SmartProject2020/Azure_Terraform_Modules (branch: poc)
# ═══════════════════════════════════════════════════════════════
# ─────────────────────────────────────────────────────────────
# Provider Entra ID (tenant Servier)
# ─────────────────────────────────────────────────────────────
module "entra_custom_domain" {
  source = "github.com/SmartProject2020/terraform_modules//custom_domain?ref=poc"
  #   Surchargé par override.tf dans le pipeline (chemin local)
  action        = var.action
  domain_name   = var.domain_name
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  output_dir    = "${path.module}/outputs"
}
