# Servier — Automatisation Custom Domain Entra ID

Automatisation de l'ajout et de la suppression de custom domains dans le tenant **Entra ID Servier**, dans le cadre de rachats d'entités externes.

Le flux est déclenché depuis **ServiceNow**, orchestré par un **pipeline Azure DevOps**, et exécuté via **Terraform**.

---

## Sommaire

- [Architecture](#architecture)
- [Flux d'exécution](#flux-dexécution)
- [Structure du projet](#structure-du-projet)
- [Prérequis](#prérequis)
- [Configuration Azure DevOps](#configuration-azure-devops)
- [Utilisation](#utilisation)
- [Notes importantes](#notes-importantes)

---

## Architecture

```
ServiceNow (formulaire Add/Remove)
    │
    │  Approbation DépartementDesMarques
    │
    ▼
Azure DevOps Pipeline (REST API webhook)
    │
    ├── Stage 1 : Validate        → validation format domaine
    ├── Stage 2 : TerraformPlan   → terraform init + plan
    ├── Stage 3 : TerraformApply  → terraform apply + extraction TXT record
    └── Stage 4 : NotifyServiceNow → callback REST API ServiceNow
            │
            │  action=add  → ticket en attente + TXT record envoyé
            │  action=remove → ticket fermé directement
            ▼
        Email à l'entité rachetée (TXT record à créer sur leur DNS on-prem)
            │
            │  Confirmation manuelle dans ServiceNow
            ▼
        Ansible (vérification DNS + Defender O365 policies)
```

---

## Flux d'exécution

### Ajout d'un domaine (`action=add`)

1. Le **Requester** remplit le formulaire ServiceNow (action=add, domain_name)
2. **Approbation** par le département des marques
3. ServiceNow appelle le **pipeline Azure DevOps** via REST API
4. Terraform crée le **custom domain dans Entra ID** et récupère la valeur du **TXT record** de vérification
5. Le pipeline effectue un **callback ServiceNow** avec le TXT record
6. ServiceNow envoie un **email à l'entité rachetée** avec les instructions DNS
7. Le ticket passe en état **"En attente"**
8. L'entité crée manuellement le TXT record sur son DNS on-premises
9. L'entité **confirme dans ServiceNow** → déclenchement Ansible
10. Ansible vérifie la propagation DNS et active le domaine dans Entra ID
11. Ansible met à jour les politiques **Defender O365** (POL-Safe_Links, POL-SAFE-ATTACHMENT)

### Suppression d'un domaine (`action=remove`)

1. Le **Requester** remplit le formulaire ServiceNow (action=remove, domain_name)
2. **Approbation** par le département des marques
3. ServiceNow appelle le **pipeline Azure DevOps** via REST API
4. Terraform **supprime le custom domain** du tenant Entra ID
5. Le pipeline **ferme le ticket ServiceNow** directement

---

## Structure du projet

Le code est réparti sur **deux repos GitHub distincts** :

### Repo root — `SmartProject2020/Azure_Terraform_Services` (branch: `poc`)
Point d'entrée du pipeline. Contient le module root et le pipeline Azure DevOps.

```
.
├── root/
│   ├── main.tf          # Provider azuread + appel module child (source GitHub)
│   ├── variables.tf     # tenant_id, client_id, client_secret, action, domain_name
│   └── outputs.tf       # Réexpose les outputs du module child
│
├── pipelines/
│   └── azure-pipeline.yml   # Pipeline Azure DevOps (4 stages)
│
└── README.md
```

### Repo module — `SmartProject2020/Azure_Terraform_Modules` (branch: `master`)
Bibliothèque de modules Terraform réutilisables.

```
.
└── Dns_Txt_Record/
    ├── main.tf          # Validation + azuread_domain + export JSON TXT record
    ├── variables.tf     # action, domain_name, output_dir
    └── outputs.tf       # txt_record_value, domain_verified, export_path
```

> Le module child est référencé dans `root/main.tf` via :
> ```hcl
> source = "github.com/SmartProject2020/Azure_Terraform_Modules//Dns_Txt_Record?ref=master"
> ```
> Terraform le télécharge automatiquement lors du `terraform init`.

---

## Prérequis

### 1. Service Principal Azure AD

Un Service Principal doit être créé dans le tenant Entra ID Servier avec les permissions suivantes :

**Microsoft Graph API (Application permissions) :**

| Permission | Raison |
|---|---|
| `Domain.ReadWrite.All` | Créer / supprimer des custom domains |
| `Directory.ReadWrite.All` | Lire l'état des domains dans Entra ID |

> ⚠️ Ces permissions nécessitent un **consentement administrateur** (Admin Consent) dans Entra ID.

**Création via Azure CLI :**
```bash
# Création du Service Principal
az ad sp create-for-rbac --name "sp-servier-entra-domain-automation" --skip-assignment

# Attribution des permissions Graph (à faire dans le portail Azure ou via Graph API)
# Entra ID > App Registrations > sp-servier-entra-domain-automation
# > API Permissions > Add > Microsoft Graph > Application
# > Domain.ReadWrite.All + Directory.ReadWrite.All > Grant admin consent
```

---

### 2. Backend Terraform (Azure Storage)

Un Storage Account Azure doit exister pour stocker le state Terraform.

```bash
# Création du Resource Group pour le state
az group create --name "rg-tfstate-servier" --location "westeurope"

# Création du Storage Account
az storage account create \
  --name "serviertfstate" \
  --resource-group "rg-tfstate-servier" \
  --sku Standard_LRS \
  --encryption-services blob

# Création du container
az storage container create \
  --name "tfstate" \
  --account-name "serviertfstate"
```

Le Service Principal doit avoir le rôle **`Storage Blob Data Contributor`** sur ce Storage Account :
```bash
az role assignment create \
  --assignee "<client-id-du-sp>" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/rg-tfstate-servier/storageAccounts/serviertfstate"
```

---

### 3. Azure DevOps

#### Extension Terraform
Installer l'extension **Terraform** depuis le Marketplace Azure DevOps :
```
https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks
```

#### Service Connection GitHub
Service Connection existante de type **GitHub App Azure DevOps**

- Nom : `SmartProject2020` (référencé dans le pipeline sous `endpoint`)
- Type : **GitHub App** (installée sur l'organisation `SmartProject2020`)
- Donne accès aux deux repos :
  - `SmartProject2020/Azure_Terraform_Services`
  - `SmartProject2020/Azure_Terraform_Modules`

#### Variable Group : `servier-entraid-domain-vars`
À créer dans **Pipelines > Library > + Variable group**

| Variable | Description | Secret |
|---|---|:---:|
| `ARM_TENANT_ID` | ID du tenant Entra ID Servier | ✅ |
| `ARM_CLIENT_ID` | Client ID du Service Principal | ✅ |
| `ARM_CLIENT_SECRET` | Client Secret du Service Principal | ✅ |
| `ARM_SUBSCRIPTION_ID` | Subscription Azure (backend storage uniquement) | ✅ |
| `TF_BACKEND_RG` | Resource Group du Storage Account Terraform | |
| `TF_BACKEND_SA` | Nom du Storage Account Terraform | |
| `TF_BACKEND_CONTAINER` | Nom du container blob (ex: `tfstate`) | |
| `GITHUB_TOKEN` | PAT GitHub pour `terraform init` (téléchargement module privé) | ✅ |
| `SERVICENOW_USER` | Compte ServiceNow pour les callbacks REST | ✅ |
| `SERVICENOW_PASSWORD` | Mot de passe du compte ServiceNow | ✅ |

> **GITHUB_TOKEN** : générer un PAT GitHub avec le scope `repo` (read) sur le compte `SmartProject2020`.
> Il est injecté via `git config --global url."https://oauth2:TOKEN@github.com"` avant chaque `terraform init`
> pour permettre le téléchargement du module depuis le repo privé.

#### PAT Azure DevOps (pour ServiceNow)
Générer un **Personal Access Token** avec le scope `Build > Read & execute` pour permettre à ServiceNow d'appeler le pipeline via REST API.

---

### 4. ServiceNow

Les propriétés système suivantes doivent être configurées dans ServiceNow :

| Propriété | Valeur |
|---|---|
| `servier.cicd.webhook_url` | `https://dev.azure.com/{org}/{project}/_apis/pipelines/{id}/runs?api-version=7.1` |
| `servier.cicd.pat_token` | PAT Azure DevOps (base64 encodé) |

Les champs custom suivants doivent exister sur la table `sc_req_item` :

| Champ | Description |
|---|---|
| `u_domain_name` | Nom de domaine traité |
| `u_txt_record_value` | Valeur TXT record retournée par Entra ID |
| `u_pipeline_status` | Statut pipeline (`terraform_done`, `completed`) |

---

### 5. Versions requises

| Outil | Version minimum |
|---|---|
| Terraform | `>= 1.3.0` |
| Provider `hashicorp/azuread` | `~> 2.47` |
| Azure CLI | `>= 2.50.0` |
| Azure DevOps | Service `dev.azure.com` |

---

## Configuration Azure DevOps

### Créer le pipeline

1. Aller dans **Pipelines > New Pipeline**
2. Sélectionner le dépôt Git contenant ce projet
3. Choisir **Existing Azure Pipelines YAML file**
4. Sélectionner `pipelines/azure-pipeline.yml`
5. **Sauvegarder** (ne pas exécuter)
6. Récupérer l'**ID du pipeline** (visible dans l'URL) → à fournir à ServiceNow

### Autoriser le Variable Group

Dans **Pipelines > Library > servier-entraid-domain-vars** :
- Cliquer sur **Pipeline permissions**
- Autoriser le pipeline créé ci-dessus

---

## Utilisation

### Déclenchement manuel (test)

Depuis Azure DevOps, lancer le pipeline avec les paramètres :

```
action      : add
domain_name : entity-acquired.com
```

### Déclenchement depuis ServiceNow

```http
POST https://dev.azure.com/{org}/{project}/_apis/pipelines/{pipelineId}/runs?api-version=7.1

Authorization: Basic {base64(':' + PAT)}
Content-Type: application/json

{
  "templateParameters": {
    "action": "add",
    "domain_name": "entity-acquired.com",
    "servicenow_ticket_id": "abc123sys_id",
    "servicenow_callback_url": "https://{instance}.service-now.com/api/now/table/sc_req_item/{sys_id}"
  }
}
```

### Outputs Terraform disponibles après `apply`

| Output | Description |
|---|---|
| `domain_name` | Domaine traité |
| `txt_record_value` | Valeur TXT à créer sur le DNS de l'entité |
| `domain_verified` | `true` / `false` — statut dans Entra ID |
| `txt_record_export_path` | Chemin du fichier JSON exporté (artifact pipeline) |

---

## Notes importantes

**Le TXT record ne peut pas être créé automatiquement** sur le DNS de l'entité rachetée car il est hébergé on-premises et non accessible depuis Azure. L'étape de création DNS reste manuelle côté entité, ce qui est la seule interruption humaine dans le flux.

**Le state Terraform est isolé** par un fichier `entraid-domains/domains.tfstate` dans le backend Azure Storage. Ne pas modifier ce fichier manuellement.

**La migration vers OIDC** (Workload Identity Federation) est prévue pour supprimer le `ARM_CLIENT_SECRET`. Les fichiers Terraform et pipeline sont déjà préparés pour cette transition — seule la configuration du Variable Group et de la Service Connection Azure DevOps sera à modifier.