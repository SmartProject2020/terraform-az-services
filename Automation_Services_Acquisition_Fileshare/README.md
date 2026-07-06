# Automation Services — Azure Fileshare (Acquisition)

Workflow GitHub Actions pour la création de File Shares Azure en mode acquisition : crée automatiquement le Resource Group et le Storage Account s’ils n’existent pas, puis crée les fileshares et déclenche l’AD join.

## Workflow

`.github/workflows/terraform-acquisition-fileshare.yml`

## Fonctionnement

Ce workflow provisionne en **cascade** :

```
1. Resource Group        → créé si absent
2. Storage Account       → créé si absent (FileStorage, public, LRS)
3. Azure File Shares     → créés sur le SA
4. AD join               → déclenché automatiquement si azure_ad_authentication=true
                           (via terraform-register-fileshare.yml)
```

> **Différence clé** avec `terraform-fileshare.yml` : ce workflow ne requiert **pas** que le SA existe au préalable. Il crée toute la stack si nécessaire.

> Le Storage Account est **toujours public** (requis pour l’AD join Kerberos). Pas de Private Endpoint dans ce workflow.

### Convention de nommage

```
Storage Account : ${plaque}${env}${application_id}sta${STORAGE_ACCOUNT_INC}  (minuscules)
Resource Group  : ${PLAQUE}-${SETTING}-${APPLICATION_ID}-${ENV}-RG${RESOURCE_GROUP_INC}
```

**Exemple :** `em50devnxgensta08` / `EM50-NPR-NXGEN-DEV-RG08`

-----

## Inputs

|Paramètre                         |Type  |Obligatoire|Valeurs / Défaut                    |Description              |
|----------------------------------|------|-----------|------------------------------------|-------------------------|
|`operation`                       |choice|✅          |`plan` | `apply` | `destroy`        |Opération Terraform      |
|`subscription_id`                 |string|✅          |UUID                                |Subscription Azure cible |
|`plaque`                          |choice|✅          |`EM50` | `AM50` | `AP50` | `GL50`   |Plaque de déploiement    |
|`application_id`                  |string|✅          |Ex : `NXGEN`                        |Code CMDB (majuscules)   |
|`setting`                         |choice|✅          |`NPR` | `PRD`                       |Setting de déploiement   |
|`env`                             |choice|✅          |`DEV` | `TST` | `PRD` | …           |Environnement applicatif |
|`servier_environment`             |choice|✅          |Identique à `env`                   |Tag Azure                |
|`resource_group_inc`              |string|✅          |`01` (défaut)                       |Incrément du RG          |
|`storage_account_inc`             |string|✅          |`01` (défaut)                       |Incrément du SA          |
|`storage_account_kind`            |choice|❌          |`FileStorage` (défaut) | `StorageV2`|Kind du SA               |
|`storage_account_replication_type`|choice|❌          |`LRS` (défaut) | `ZRS`              |Type de réplication      |
|`fileshares`                      |string|✅          |JSON array                          |Liste des shares à créer |
|`quota_gb`                        |string|❌          |`100` (défaut)                      |Quota par fileshare en GB|
|`azure_ad_authentication`         |choice|❌          |`true` (défaut) | `false`           |Déclencher l’AD join     |
|`location`                        |string|✅          |`France Central` (défaut)           |Région Azure             |

### Format du paramètre `fileshares`

```json
["TEST", "COUCOU", "logs", "backup"]
```

> Les noms de shares sont **sensibles à la casse**. Ils sont transmis exactement tels que saisis.

-----

## Exemples d’appel

### Via API (ServiceNow) — appel simplifié

ServiceNow n’envoie que les paramètres variables. Les valeurs fixes (FileStorage, LRS, public, AD join, quota) sont gérées en interne par le workflow.

```bash
POST https://api.github.com/repos/SmartProject2020/terraform-az-services/actions/workflows/terraform-acquisition-fileshare.yml/dispatches
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
    "resource_group_inc":  "08",
    "storage_account_inc": "08",
    "fileshares":          "[\"TEST\",\"COUCOU\",\"logs\"]",
    "location":            "France Central"
  }
}
```

### Via GitHub Actions UI

Aller sur **Actions → Terraform - Acquisition Fileshare → Run workflow**, sélectionner la branche et renseigner les inputs.

-----

## Logique d’import (idempotence)

Le workflow vérifie l’existence des ressources avant chaque apply :

|Ressource|Existe dans Azure|Dans le state   |Action              |
|---------|-----------------|----------------|--------------------|
|RG       |❌                |—               |Terraform crée      |
|RG       |✅                |❌               |Import dans le state|
|RG       |✅                |✅ (ID différent)|State rm + reimport |
|SA       |❌                |—               |Terraform crée      |
|SA       |✅                |❌               |Import dans le state|
|SA       |✅                |✅ (ID différent)|State rm + reimport |

-----

## AD join

L’AD join est déclenché automatiquement en fin d’apply via l’API GitHub :

```
terraform-acquisition-fileshare.yml
    └── (apply OK + azure_ad_authentication=true)
        └── terraform-register-fileshare.yml  (runner Windows EM50SW5130)
            └── AzFilesHybrid → AD join sur fr1.grs.net
```

-----

## Naming workspace Terraform

```
${PLAQUE}-${ENV}-${APPLICATION_ID}-acquisition-fileshare-${STORAGE_ACCOUNT_INC}
```

**Exemple :** `EM50-DEV-NXGEN-acquisition-fileshare-08`

-----

## Authentification

- **Azure** : OIDC Workload Identity Federation — zéro secret, zéro rotation
- **Modules privés** : GitHub App token (TTL 1h) via `~/.netrc`
- **Secret utilisé** : `AZURE_CLIENT_ID_SC_OIDC_${PLAQUE}_${SETTING}`

-----

## Pré-requis

- Runner self-hosted Linux : `Automation_linux_pool` (étapes Terraform)
- Runner self-hosted Windows : `Automation_win_pool` (AD join via `terraform-register-fileshare`)
- Secrets GitHub : `AZURE_CLIENT_ID_SC_OIDC_*`, `GH_APP_PRIVATE_KEY`
- Variables GitHub : `AZURE_TENANT_ID`, `GH_APP_ID`, `GH_APP_INSTALLATION_ID`
- Fichier backend : `backends/${PLAQUE}-${ENV}.tfbackend`
- Module root : `Automation_Services_Acquisition_Fileshare/`