# MTA-STS — Azure Static Web App

Déploiement automatisé de la stratégie [MTA-STS (RFC 8461)](https://datatracker.ietf.org/doc/html/rfc8461) via Azure Static Web App, Terraform et GitHub Actions.

> **Référence officielle Microsoft** : [Amélioration du flux de messagerie avec MTA-STS](https://learn.microsoft.com/fr-fr/purview/enhancing-mail-flow-with-mta-sts)

---

## Architecture

```
GitHub (code + CI/CD)
    │
    ├── .github/workflows/infra.yml   → Terraform → Azure Static Web App
    └── .github/workflows/deploy.yml  → SWA Deploy → app/
                                                         ├── .well-known/mta-sts.txt
                                                         ├── index.html
                                                         └── staticwebapp.config.json
```

**DNS requis :**
| Type  | Nom                     | Valeur                              |
|-------|-------------------------|-------------------------------------|
| CNAME | `mta-sts.<domain>`      | `<swa-name>.azurestaticapps.net`    |
| TXT   | `_mta-sts.<domain>`     | `v=STSv1; id=<POLICY_ID>Z;`        |

---

## Prérequis

- Compte Azure avec une souscription active
- Azure CLI (`az`) installé
- Terraform ≥ 1.5
- GitHub repository
- Domaine email dont l'enregistrement MX pointe vers Exchange Online

---
## Phase 1 — 

### 1. Configurer le secret GitHub minimal

Un seul secret est requis (`Settings → Secrets and variables → Actions → Secrets`) :

| Secret           | Description                                                        |
|------------------|--------------------------------------------------------------------|
| `GH_PAT_SECRETS` | GitHub PAT avec scope `secrets:write` (export auto du token SWA)  |

> Les credentials Azure (`CLIENT_ID`, `TENANT_ID`, `SUBSCRIPTION_ID`) et les paramètres Terraform sont passés directement comme **inputs** lors du déclenchement manuel du workflow.

---

## Phase 2 — Premier déploiement

### 1. Générer le Policy ID initial

```bash
bash scripts/generate-policy-id.sh
# → ex: 20260424120000
# Notez cette valeur, elle sera saisie comme input au lancement du workflow
```

> Le policy ID ne doit être régénéré **que lorsque le contenu de `mta-sts.txt` change** (mode, MX, max_age). Le rôle du policy ID : les serveurs de messagerie mettent en cache la stratégie MTA-STS. Quand ils voient l'enregistrement TXT _mta-sts, ils comparent l'ID avec celui en cache. Si l'ID est différent → ils re-téléchargent mta-sts.txt. Si l'ID est identique → ils gardent le cache.

### 2. Lancer le workflow Terraform

Aller sur **GitHub → Actions → Infrastructure (Terraform) → Run workflow** et renseigner les inputs :

| Input                      | Valeur                              |
|----------------------------|-------------------------------------|
| Azure Client ID            | App ID du Service Principal         |
| Azure Tenant ID            | Tenant ID Azure AD                  |
| Azure Subscription ID      | ID de la souscription               |
| domain                     | `contoso.com`                       |
| policy_id                  | Valeur générée à l'étape précédente |
| policy_mode                | `testing`                           |
| custom_domain_configured   | `false`                             |

Après le `terraform apply`, notez le **SWA hostname** dans les outputs :
```
swa_default_hostname = "random-name.azurestaticapps.net"
```

### 3. Déployer le contenu de la stratégie

Aller sur **GitHub → Actions → Deploy MTA-STS Policy → Run workflow**.

> Cette étape est indépendante de Terraform. Elle pousse les fichiers `app/` vers le SWA (dont `mta-sts.txt`). Sans elle, toute URL vers `/.well-known/mta-sts.txt` retourne 404.

### 4. Créer l'enregistrement CNAME DNS

Chez votre fournisseur DNS :

| Type  | Nom           | Valeur                              | TTL  |
|-------|---------------|-------------------------------------|------|
| CNAME | `mta-sts`     | `random-name.azurestaticapps.net`   | 3600 |

> Si votre DNS est géré par **Azure DNS**, décommentez les variables `azure_dns_zone_*` dans `terraform.tfvars` : Terraform crée les enregistrements automatiquement.

### 5. Activer le domaine personnalisé

Relancer le workflow **Infrastructure (Terraform)** via `workflow_dispatch` avec les mêmes valeurs qu'à l'étape 2, en passant `custom_domain_configured` à `true`.

### 6. Créer l'enregistrement TXT DNS

| Type | Nom          | Valeur                              | TTL  |
|------|--------------|-------------------------------------|------|
| TXT  | `_mta-sts`   | `v=STSv1; id=20260424120000Z;`      | 3600 |

---

## Phase 3 — Validation

```bash
# Vérifier l'URL de la stratégie
curl https://mta-sts.<votre-domaine>/.well-known/mta-sts.txt

# Vérifier l'enregistrement TXT DNS
nslookup -type=TXT _mta-sts.<votre-domaine>

# Outils de validation tiers
# https://www.checktls.com/
# https://mxtoolbox.com/mta-sts.aspx
```

Résultat attendu de la stratégie :
```
version: STSv1
mode: testing
mx: *.mail.protection.outlook.com
max_age: 604800
```

---

## Phase 4 — Passer en mode enforce

Une fois la configuration validée :

1. Modifier `app/.well-known/mta-sts.txt` : remplacer `mode: testing` par `mode: enforce`
2. Générer un nouveau Policy ID :
   ```bash
   bash scripts/generate-policy-id.sh
   ```
3. Mettre à jour l'enregistrement TXT DNS avec le nouvel ID
4. Committer et pousser les changements → le workflow `deploy.yml` se déclenche automatiquement
5. Relancer le workflow **Infrastructure (Terraform)** via `workflow_dispatch` avec `policy_mode=enforce` et le nouvel ID

> **Important** : Mettre à jour le Policy ID dans le TXT DNS APRÈS avoir déployé le nouveau fichier `mta-sts.txt`, pour éviter tout désalignement.

---

## Mise à jour de la stratégie

À chaque modification de `mta-sts.txt` (mode, MX, max_age) :

```bash
# 1. Modifier app/.well-known/mta-sts.txt

# 2. Générer un nouveau policy_id
bash scripts/generate-policy-id.sh

# 3. Mettre à jour le TXT DNS : v=STSv1; id=<NEW_ID>Z;

# 4. Commit + push (déclenche deploy.yml automatiquement)
git add app/.well-known/mta-sts.txt
git commit -m "feat: update MTA-STS policy"
git push origin main

# 5. Relancer infra.yml via workflow_dispatch avec le nouvel policy_id
```

---

## Structure du projet

```
mta-sts-azure/
├── .github/
│   └── workflows/
│       ├── infra.yml                  # Terraform CI/CD (provision Azure)
│       └── deploy.yml                 # Déploiement contenu SWA
├── terraform/
│   ├── providers.tf                   # Provider AzureRM + backend
│   ├── main.tf                        # Ressources Azure
│   ├── variables.tf                   # Variables d'entrée
│   ├── outputs.tf                     # Outputs (hostname, token, DNS)
│   ├── backend.conf                   # Config backend Terraform (commité)
│   ├── backend.conf.example           # Exemple de référence
│   └── terraform.tfvars.example       # Variables (à copier)
├── app/
│   ├── .well-known/
│   │   └── mta-sts.txt               # Stratégie MTA-STS
│   ├── index.html                     # Page d'accueil SWA
│   └── staticwebapp.config.json       # Routage et headers SWA
├── scripts/
│   └── generate-policy-id.sh          # Génère un policy_id UTC
└── .gitignore
```

---

## Troubleshooting

| Problème | Cause probable | Solution |
|----------|----------------|----------|
| `mta-sts.txt` retourne 404 | SWA pas encore déployé | Vérifier le workflow `deploy.yml` |
| Domaine personnalisé refusé | CNAME DNS absent ou non propagé | Attendre la propagation DNS (jusqu'à 48h) |
| Certificat TLS invalide | Azure SWA émet le certificat automatiquement | Attendre 5-10 min après validation du domaine |
| Policy ID non mis à jour | Expéditeurs utilisent le cache | Attendre expiration du `max_age` ou changer l'ID |
| OIDC auth échoue | Federated credential mal configuré | Vérifier `subject` dans az ad app federated-credential |
