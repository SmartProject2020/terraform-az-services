# Automation Services — Resource Group

Workflow GitHub Actions pour la création, modification et suppression de Resource Groups Azure via Terraform.

## Workflow

`.github/workflows/terraform-resource-group.yml`

## Fonctionnement

Ce workflow provisionne un **Azure Resource Group** avec ses tags Servier. Il est déclenché par ServiceNow ou manuellement via l’interface GitHub Actions.

### Convention de nommage

```
${PLAQUE}-${SETTING}-${APPLICATION_ID}-${ENV}-RG${RESOURCE_GROUP_INC}
```

**Exemple :** `EM50-NPR-NXGEN-DEV-RG01`

### Logique de déploiement

```
1. Résolution secret OIDC + backend tfstate
2. Azure Login (OIDC — zero secret)
3. Import du RG dans le state si déjà existant (fix changement d'incrément)
4. Terraform plan / apply / destroy
```

> **Destroy interdit en setting PRD** — garde-fou intégré dans le workflow.

-----

## Inputs

|Paramètre            |Type  |Obligatoire|Valeurs                          |Description                            |
|---------------------|------|-----------|---------------------------------|---------------------------------------|
|`operation`          |choice|✅          |`plan` | `apply` | `destroy`     |Opération Terraform                    |
|`subscription_id`    |string|✅          |UUID                             |Subscription Azure cible               |
|`plaque`             |choice|✅          |`EM50` | `AM50` | `AP50` | `GL50`|Plaque de déploiement                  |
|`application_id`     |string|✅          |Ex : `NXGEN`                     |Code CMDB de l’application (majuscules)|
|`setting`            |choice|✅          |`NPR` | `PRD`                    |Setting de déploiement                 |
|`env`                |choice|✅          |`DEV` | `TST` | `UAT` | `PRD` | …|Environnement applicatif               |
|`servier_environment`|choice|✅          |Identique à `env`                |Tag Azure Servier environment          |
|`resource_group_inc` |string|✅          |Ex : `01`                        |Incrément du Resource Group            |
|`location`           |string|✅          |`France Central` (défaut)        |Région Azure                           |

### Régions disponibles

|Région             |Valeur `location`|Plaque|
|-------------------|-----------------|------|
|Europe             |`France Central` |EM50  |
|Americas           |`East US`        |AM50  |
|Asia-Pacific       |`Southeast Asia` |AP50  |
|**Central India** 🆕|`Central India`  |AP50  |

-----

## Exemples d’appel

### Via GitHub Actions UI

Aller sur **Actions → Terraform - Resource Group → Run workflow**, renseigner les inputs et lancer.

### Via API (ServiceNow)

```bash
POST https://api.github.com/repos/servier-github/terraform-az-services/actions/workflows/terraform-resource-group.yml/dispatches
Authorization: Bearer {GITHUB_APP_TOKEN}
Accept: application/vnd.github+json

{
  "ref": "main",
  "inputs": {
    "operation":           "apply",
    "subscription_id":     "603402ed-1313-4cbe-8916-d154303fa560",
    "plaque":              "EM50",
    "application_id":      "NXGEN",
    "setting":             "NPR",
    "env":                 "DEV",
    "servier_environment": "DEV",
    "resource_group_inc":  "01",
    "location":            "France Central"
  }
}
```

-----

## Naming workspace Terraform

```
${PLAQUE}-${SETTING}-${APPLICATION_ID}-${ENV}-${RESOURCE_GROUP_INC}
```

**Exemple :** `EM50-NPR-NXGEN-DEV-01`

-----

## Authentification

- **Azure** : OIDC Workload Identity Federation — zéro secret, zéro rotation
- **Modules privés** : GitHub App token (TTL 1h)
- **Secret utilisé** : `AZURE_CLIENT_ID_SC_OIDC_${PLAQUE}_${SETTING}`

-----

## Pré-requis

- Runner self-hosted : `Automation_linux_pool`
- Secret GitHub : `AZURE_CLIENT_ID_SC_OIDC_EM50_NPR` (ou équivalent selon plaque/setting)
- Variable GitHub : `AZURE_TENANT_ID`, `GH_APP_ID`, `GH_APP_INSTALLATION_ID`
- Secret GitHub : `GH_APP_PRIVATE_KEY`
- Fichier backend : `backends/${PLAQUE}-${ENV}.tfbackend`