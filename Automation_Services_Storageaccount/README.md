# Automation Services — Storage Account

Workflow GitHub Actions pour la création, modification et suppression de Storage Accounts Azure via Terraform.

## Workflow

`.github/workflows/terraform-storage-account.yml`

## Fonctionnement

Ce workflow provisionne un **Azure Storage Account** avec son Resource Group et, si le type réseau est `private`, un **Private Endpoint** associé.

### Convention de nommage

```
Storage Account : ${plaque}${env}${application_id}sta${STORAGE_ACCOUNT_INC}  (minuscules)
Resource Group  : ${PLAQUE}-${SETTING}-${APPLICATION_ID}-${ENV}-RG${RESOURCE_GROUP_INC}
Private Endpoint: ${PLAQUE}-${ENV}-${APPLICATION_ID}-PE${PE_INC}
```

**Exemple :** `em50prdhrim0sta01` / `EM50-PRD-HRIM0-PRD-RG01`

### Logique de déploiement

```
1. Résolution secret OIDC + backend + hub subscription (si private)
2. Azure Login (OIDC)
3. Dérivation du tier (FileStorage → Premium / StorageV2 → Standard)
4. Résolution du zoning réseau (si private) → subnet / vnet
5. Import RG + SA + PE dans le state si existants (fix changement d'incrément)
6. Terraform plan / apply / destroy
```

> **Destroy** : détruit PE d’abord, puis SA (ordre garanti). Interdit en setting PRD.

> **Premium blob** : requiert `kind=BlockBlobStorage` (pas StorageV2). LRS/ZRS uniquement.

-----

## Inputs

|Paramètre                         |Type  |Obligatoire|Valeurs                                                   |Description                           |
|----------------------------------|------|-----------|----------------------------------------------------------|--------------------------------------|
|`operation`                       |choice|✅          |`plan` | `apply` | `destroy`                              |Opération Terraform                   |
|`subscription_id`                 |string|✅          |UUID                                                      |Subscription Azure cible              |
|`plaque`                          |choice|✅          |`EM50` | `AM50` | `AP50` | `GL50`                         |Plaque de déploiement                 |
|`application_id`                  |string|✅          |Ex : `HRIM0`                                              |Code CMDB (majuscules)                |
|`setting`                         |choice|✅          |`NPR` | `PRD`                                             |Setting de déploiement                |
|`env`                             |choice|✅          |`DEV` | `TST` | `PRD` | …                                 |Environnement applicatif              |
|`servier_environment`             |choice|✅          |Identique à `env`                                         |Tag Azure                             |
|`storage_account_type`            |choice|✅          |`public` | `private`                                      |Type d’accès réseau                   |
|`storage_account_kind`            |choice|✅          |`StorageV2` | `BlobStorage` | `FileStorage`               |Kind du SA                            |
|`storage_account_replication_type`|choice|✅          |`LRS` | `ZRS` | `GRS`                                     |Type de réplication                   |
|`storage_account_access_tier`     |choice|✅          |`Hot` | `Cool`                                            |Tier d’accès (ignoré pour FileStorage)|
|`sftp_enabled`                    |choice|❌          |`false` (défaut) | `true`                                 |SFTP (StorageV2 uniquement)           |
|`zoning`                          |choice|❌          |`prod-critical` | `prod-standard` | `nonprod-critical` | …|Zoning réseau (requis si private)     |
|`resource_group_inc`              |string|✅          |`01` (défaut)                                             |Incrément du RG                       |
|`storage_account_inc`             |string|✅          |`01` (défaut)                                             |Incrément du SA                       |
|`endpoint_resource_type`          |choice|❌          |`blob` (défaut) | `file`                                  |Sous-ressource PE                     |
|`location`                        |string|✅          |`France Central` (défaut)                                 |Région Azure                          |

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

### SA privé (blob, StorageV2, PRD)

```bash
POST https://api.github.com/repos/SmartProject2020/terraform-az-services/actions/workflows/terraform-storage-account.yml/dispatches
Authorization: Bearer {GITHUB_APP_TOKEN}
Accept: application/vnd.github+json

{
  "ref": "main",
  "inputs": {
    "operation":                       "apply",
    "subscription_id":                 "82b61300-dd3d-4331-b2a6-fa53bb6ba322",
    "plaque":                          "EM50",
    "application_id":                  "HRIM0",
    "setting":                         "PRD",
    "env":                             "PRD",
    "servier_environment":             "PRD",
    "storage_account_type":            "private",
    "storage_account_kind":            "StorageV2",
    "storage_account_replication_type":"LRS",
    "storage_account_access_tier":     "Hot",
    "zoning":                          "prod-critical",
    "resource_group_inc":              "01",
    "storage_account_inc":             "01",
    "endpoint_resource_type":          "blob",
    "location":                        "France Central"
  }
}
```

### SA public (FileStorage, NPR)

```bash
{
  "ref": "main",
  "inputs": {
    "operation":                        "apply",
    "subscription_id":                  "603402ed-1313-4cbe-8916-d154303fa560",
    "plaque":                           "EM50",
    "application_id":                   "NXGEN",
    "setting":                          "NPR",
    "env":                              "DEV",
    "servier_environment":              "DEV",
    "storage_account_type":             "public",
    "storage_account_kind":             "FileStorage",
    "storage_account_replication_type": "LRS",
    "storage_account_access_tier":      "Hot",
    "resource_group_inc":               "01",
    "storage_account_inc":              "01",
    "location":                         "France Central"
  }
}
```

-----

## Naming workspace Terraform

```
${PLAQUE}-${SETTING}-${APPLICATION_ID}-${ENV}-${STORAGE_ACCOUNT_INC}
```

**Exemple :** `EM50-PRD-HRIM0-PRD-01`

-----

## Authentification

- **Azure** : OIDC Workload Identity Federation — zéro secret, zéro rotation
- **Hub subscription** (PE privé) : provider alias `azurerm.hub_subscription`
- **Secret utilisé** : `AZURE_CLIENT_ID_SC_OIDC_${PLAQUE}_${SETTING}`

-----

## Pré-requis

- Runner self-hosted : `Automation_linux_pool`
- Secrets GitHub : `AZURE_CLIENT_ID_SC_OIDC_*`, `GH_APP_PRIVATE_KEY`
- Variables GitHub : `AZURE_TENANT_ID`, `GH_APP_ID`, `GH_APP_INSTALLATION_ID`
- Fichier backend : `backends/${PLAQUE}-${ENV}.tfbackend`