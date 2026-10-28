# 📄 providers.tf - Configuration du Provider CloudStack

## 📌 Vue d'ensemble

Ce fichier configure le **provider CloudStack** qui permet à Terraform de communiquer avec l'API CloudStack.

## 📋 Contenu Complet

```hcl
terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "0.5.0"
    }
  }
}

provider "cloudstack" {
  api_url    = var.api_url
  api_key    = var.api_key
  secret_key = var.secret_key
}
```

## 🔧 Configuration Détaillée

### Bloc `terraform { required_providers {} }`

Déclare les providers requis par cette configuration Terraform.

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `source` | `cloudstack/cloudstack` | Namespace du provider |
| `version` | `0.5.0` | Version du provider CloudStack |

**Version Requise** : CloudStack Provider **0.5.0**  
(Version précédente : 0.4.0, versions récentes : 0.6.0+)

### Bloc `provider "cloudstack" {}`

Configure la connexion à CloudStack via l'API.

| Argument | Type | Requis | Source | Description |
|----------|------|--------|--------|-------------|
| `api_url` | string | ✅ | `var.api_url` | URL de l'API CloudStack |
| `api_key` | string | ✅ | `var.api_key` | Clé API pour authentification |
| `secret_key` | string | ✅ | `var.secret_key` | Clé secrète (authentication) |

## 🔐 Authentification

### Approche 1 : terraform.tfvars (Recommandé)

```hcl
# terraform.tfvars
api_url    = "http://192.168.18.20:8080/client/api"
api_key    = "hSzrvLYGRSafr_Pz2SSTCQwAX-OfeIciLCqPXHKg3D8eZvAI6Dpeledq00BWggX-eA6b-f_F63tWNOGRWjTp-g"
secret_key = "QA2589c5O1vRDrzy7l2Ntb7Vswbyl0-XBV1jrd6eiaxE8j2bbEWa81gGkDlL_puTafR59B_FzbHSaG3ByVBvXQ"
```

### Approche 2 : Variables d'Environnement

```bash
# Définir les variables d'environnement
export CLOUDSTACK_API_URL="http://192.168.18.20:8080/client/api"
export CLOUDSTACK_API_KEY="<your-api-key>"
export CLOUDSTACK_SECRET_KEY="<your-secret-key>"

# Terraform les utilisera automatiquement
terraform plan
```

### Approche 3 : Options CLI

```bash
terraform plan \
  -var="api_url=http://192.168.18.20:8080/client/api" \
  -var="api_key=<your-key>" \
  -var="secret_key=<your-secret>"
```

### Hiérarchie de Priorité

```
1. Options CLI (-var)          (Plus haute priorité)
2. terraform.tfvars
3. Variables d'environnement
4. Valeurs par défaut dans variables.tf
                               (Plus basse priorité)
```

## 📍 Exemple : Configuration CloudStack 4.22.0

```bash
# URL CloudStack
CLOUDSTACK_API_URL="http://192.168.18.20:8080/client/api"

# Pour obtenir les clés API :
# 1. Se connecter au UI CloudStack (http://192.168.18.20:8080/client)
# 2. Menu → Accounts → User → Votre utilisateur
# 3. View API Keys
# 4. Copier API Key et Secret Key
```

## ✅ Validation

### Tester la Connexion

```bash
# Valider la configuration
terraform validate
# Output:
# Success! The configuration is valid.

# Afficher les ressources disponibles
terraform providers
# Output:
# Providers required by configuration:
# .
# └── provider[registry.terraform.io/cloudstack/cloudstack] 0.5.0

# Afficher le schéma du provider
terraform providers schema
```

### Erreurs Courantes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `Missing required provider` | Provider non installé | `terraform init` |
| `connection refused` | URL CloudStack invalide | Vérifier `api_url` |
| `Unauthorized` | Clés API invalides | Vérifier `api_key` et `secret_key` |
| `Invalid URL` | Format URL incorrect | Vérifier format http:// ou https:// |

## 🔄 Variables Liées

Ce fichier utilise les variables définies dans [variables.tf](variables.tf) :

```hcl
variable "api_url" {
  description = "CloudStack API URL"
  type        = string
}

variable "api_key" {
  description = "CloudStack API Key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "CloudStack Secret Key"
  type        = string
  sensitive   = true
}
```

## 🛡️ Sécurité

### ⚠️ Ne Pas Committer les Secrets

```bash
# .gitignore
terraform.tfvars        # Contient les secrets!
terraform.tfvars.json
*.secret
.env
```

### Bonnes Pratiques

✅ **À Faire**

- Utiliser des variables d'environnement en développement
- Utiliser Vault ou Secrets Manager en production
- Utiliser `-sensitive` pour les variables sensibles
- Nettoyer les logs contenant des secrets
- Utiliser `terraform output` au lieu d'afficher les secrets

❌ **À Éviter**

- Committer `terraform.tfvars` avec les vraies clés
- Afficher les credentials dans les logs
- Stocker les secrets en dur dans le code
- Partager les fichiers contenant des API keys

## 📚 Documentation CloudStack

### Accéder aux Credentials

```
CloudStack UI → http://192.168.18.20:8080/client
  ↓
Menu Utilisateur → Accounts
  ↓
Sélectionner l'utilisateur
  ↓
Cliquer sur "View API Keys"
  ↓
Copier API Key et Secret Key
```

### Configuration CloudStack Minimale

```
- Zone : Focus-Zone
- URL API : http://192.168.18.20:8080/client/api
- Utilisateur : admin ou compte spécifique
- Permissions : au minimum "User" pour déployer des instances
```

## 🔗 Commandes Associées

```bash
# Initialiser Terraform (télécharge le provider)
terraform init

# Valider la configuration
terraform validate

# Afficher le provider utilisé
terraform version

# Afficher les informations du provider
terraform providers

# Afficher le schéma du provider
terraform providers schema -json | jq '.provider_schemas | keys'
```

## 🎯 Résumé

| Élément | Valeur |
|--------|--------|
| **Provider** | cloudstack/cloudstack |
| **Version** | 0.5.0 |
| **Configuration** | API URL + Clés d'authentification |
| **Sensibilité** | Contient des secrets ! |
| **Fichiers Liés** | `variables.tf`, `terraform.tfvars` |

---

**Version** : 1.0  
**Date** : 16 avril 2026  
**Statut** : ✅ Validé
