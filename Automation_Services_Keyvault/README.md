# Automation Services — Key Vault

Workflow GitHub Actions pour la création, modification et suppression de Key Vaults Azure via Terraform.

## Workflow

`.github/workflows/terraform-keyvault.yml`

## Fonctionnement

Ce workflow provisionne un **Azure Key Vault** avec son Resource Group et son **Private Endpoint** (toujours privé — sous-ressource `vault`).

### Convention de nommage

```
Key Vault      : ${PLAQUE}-${ENV}-${APPLICATION_ID}-KV${KEYVAULT_INC}
Resource Group : ${PLAQUE}-${SETTING}-${APPLICATION_ID}-${ENV}-RG${RESOURCE_GROUP_INC}
```

**Exemple :** `EM50-PRD-AZUEN-KV02` / `EM50-PRD-AZUEN-PRD-RG01`

### Logique de déploiement

```
1. Résolution secret OIDC + backend
2. Azure Login (OIDC)
3. Import RG + KV + PE dans le state si existants (fix changement d'incrément)
4. Terraform plan / apply / destroy
```

> **Le Key Vault est toujours privé** — un Private Endpoint (sous-ressource `vault`) est systématiquement créé.

> **Soft-delete** : irréversible depuis 2020. En cas de conflit de nom (KV supprimé récemment), utiliser un incrément supérieur (ex : `02`).

> **Destroy interdit en setting PRD** — garde-fou intégré dans le workflow.

-----

## Inputs

|Paramètre                 |Type  |Obligatoire|Valeurs                                                                                                           |Description                                |
|--------------------------|------|-----------|------------------------------------------------------------------------------------------------------------------|-------------------------------------------|
|`operation`               |choice|✅          |`plan` | `apply` | `destroy`                                                                                      |Opération Terraform                        |
|`subscription_id`         |string|✅          |UUID                                                                                                              |Subscription Azure cible                   |
|`plaque`                  |choice|✅          |`EM50` | `AM50` | `AP50` | `GL50`                                                                                 |Plaque de déploiement                      |
|`application_id`          |string|✅          |Ex : `AZUEN`                                                                                                      |Code CMDB (majuscules)                     |
|`setting`                 |choice|✅          |`NPR` | `PRD`                                                                                                     |Setting de déploiement                     |
|`env`                     |choice|✅          |`DEV` | `TST` | `PRD` | …                                                                                         |Environnement applicatif                   |
|`servier_environment`     |choice|✅          |Identique à `env`                                                                                                 |Tag Azure                                  |
|`resource_group_inc`      |string|✅          |`01` (défaut)                                                                                                     |Incrément du RG                            |
|`zoning`                  |choice|✅          |`prod-critical` | `prod-standard` | `prod-internet` | `nonprod-critical` | `nonprod-standard` | `nonprod-internet`|Zoning réseau (toujours requis)            |
|`keyvault_inc`            |string|✅          |`01` (défaut)                                                                                                     |Incrément du Key Vault                     |
|`dns_zone_subscription_id`|string|❌          |`a96e6018-...` (défaut Hub GL50)                                                                                  |Subscription hébergeant la Private DNS Zone|
|`location`                |string|✅          |`France Central` (défaut)                                                                                         |Région Azure                               |

### Table de dérivation du zoning

|Setting|Criticité|`zoning`          |
|-------|---------|------------------|
|PRD    |critical |`prod-critical`   |
|PRD    |standard |`prod-standard`   |
|PRD    |internet |`prod-internet`   |
|NPR    |critical |`nonprod-critical`|
|NPR    |standard |`nonprod-standard`|
|NPR    |internet |`nonprod-internet`|

-----

## Exemples d’appel

### Via API (ServiceNow)

```bash
POST https://api.github.com/repos/SmartProject2020/terraform-az-services/actions/workflows/terraform-keyvault.yml/dispatches
Authorization: Bearer {GITHUB_APP_TOKEN}
Accept: application/vnd.github+json

{
  "ref": "main",
  "inputs": {
    "operation":           "apply",
    "subscription_id":     "82b61300-dd3d-4331-b2a6-fa53bb6ba322",
    "plaque":              "EM50",
    "application_id":      "AZUEN",
    "setting":             "PRD",
    "env":                 "PRD",
    "servier_environment": "PRD",
    "resource_group_inc":  "01",
    "zoning":              "prod-standard",
    "keyvault_inc":        "02",
    "location":            "France Central"
  }
}
```

-----

## Naming workspace Terraform

```
${PLAQUE}-${ENV}-${APPLICATION_ID}-keyvault-${KEYVAULT_INC}
```

**Exemple :** `EM50-PRD-AZUEN-keyvault-02`

-----

## Point d’attention — Soft-delete

Le soft-delete est **obligatoire et irréversible** sur tous les Key Vaults Azure depuis 2020. En cas de conflit (KV supprimé récemment avec le même nom) :

- **Option recommandée** : utiliser `keyvault_inc` supérieur (ex : `02`)
- **Option alternative** : attendre la purge automatique (90 jours)
- **Option avancée** : demander le rôle `Key Vault Contributor` au SP pour pouvoir purger manuellement

-----

## Authentification

- **Azure** : OIDC Workload Identity Federation — zéro secret, zéro rotation
- **Secret utilisé** : `AZURE_CLIENT_ID_SC_OIDC_${PLAQUE}_${SETTING}`

-----

## Pré-requis

- Runner self-hosted : `Automation_linux_pool`
- Secrets GitHub : `AZURE_CLIENT_ID_SC_OIDC_*`, `GH_APP_PRIVATE_KEY`
- Variables GitHub : `AZURE_TENANT_ID`, `GH_APP_ID`, `GH_APP_INSTALLATION_ID`
- Fichier backend : `backends/${PLAQUE}-${ENV}.tfbackend`