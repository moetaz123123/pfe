# 📚 Terraform Configuration pour CloudStack - Guide Complet

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Structure des Fichiers](#structure-des-fichiers)
4. [Prérequis](#prérequis)
5. [Configuration](#configuration)
6. [Déploiement](#déploiement)
7. [Fichiers Détaillés](#fichiers-détaillés)
8. [Commandes Utiles](#commandes-utiles)

---

## Vue d'ensemble

Cette configuration Terraform déploie une **infrastructure Kubernetes complète sur CloudStack 4.22.0** avec :

- ✅ **Instances VM** : 1 Master + 3 Workers (configurables)
- ✅ **Réseau Isolé** : Réseau privé dédié pour le cluster
- ✅ **Load Balancer** : Distribution de charge pour les services web
- ✅ **Security Groups** : Contrôle d'accès réseau
- ✅ **IP Publique** : Pour accès externe au LB

**Provider CloudStack** : v0.5.0  
**Version Terraform** : >= 1.0

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Internet (Public)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
                 ┌──────────────────┐
                 │  Load Balancer   │ (cloudstack_ipaddress.lb)
                 │  IP Publique     │
                 └────────┬─────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
    ┌────────┐        ┌────────┐       ┌────────┐
    │ Master │        │Worker1 │       │Worker2 │
    │  :80   │        │  :80   │       │  :80   │
    └────┬───┘        └────┬───┘       └────┬───┘
         │                 │                │
         └─────────────────┼────────────────┘
                           │
              ┌────────────▼────────────┐
              │  Réseau Isolé (LAN)    │
              │  10.0.0.0/24 ou autre  │
              │  cloudstack_network    │
              └────────────────────────┘
```

---

## Structure des Fichiers

```
terraform/
├── README.md                          # 📖 Ce fichier (guide complet)
├── providers.tf                       # Configuration du provider CloudStack
├── variables.tf                       # Variables d'entrée
├── main.tf                           # Configuration générale
├── outputs.tf                        # Sorties Terraform
├── terraform.tfvars                  # Valeurs des variables (secrets)
├── cloudstack_network.tf             # Création du réseau isolé
├── cloudstack_instance.tf            # Instances VM (Master + Workers)
├── cloudstack_firewall.tf            # Security Groups
├── cloudstack_template.tf            # Lookup du template VM
├── cloudstack_loadbalancer.tf        # Load Balancer et IP publique
├── CONFIGURATION.md                  # 📋 Configuration détaillée (archive)
└── templates/
    └── inventory.tpl                 # Template Ansible inventory
```

---

## Prérequis

### Éléments Requis dans CloudStack

- ✅ **Zone** : Exemple `Focus-Zone`
- ✅ **Network Offering** : Exemple `DefaultIsolatedNetworkOfferingWithSourceNatService`
- ✅ **Service Offering** : Exemple `Rocky offer` (compute resources)
- ✅ **Template VM** : Exemple `Debian 11` (OS image)
- ✅ **SSH Keypair** : Exemple `vm-keys` (déjà créée dans CloudStack)

### Credentials CloudStack

```bash
export CLOUDSTACK_API_URL="http://192.168.18.20:8080/client/api"
export CLOUDSTACK_API_KEY="<your-api-key>"
export CLOUDSTACK_SECRET_KEY="<your-secret-key>"
```

### Fichiers Locaux

```bash
# Clé SSH locale correspondant à la keypair CloudStack
~/.ssh/vm-keys.pem
chmod 600 ~/.ssh/vm-keys.pem
```

---

## Configuration

### 1️⃣ Initialiser Terraform

```bash
cd /media/sf_pfe_cloudstack/terraform

# Télécharger les providers et initialiser
terraform init
```

### 2️⃣ Configurer terraform.tfvars

```bash
# Créer/Éditer le fichier terraform.tfvars
cat > terraform.tfvars << 'EOF'
# API CloudStack
api_url    = "http://192.168.18.20:8080/client/api"
api_key    = "hSzrvLYGRSafr_Pz2..."
secret_key = "QA2589c5O1vRDrzy7l..."

# Zone et Réseau
zone                = "Focus-Zone"
network_name        = "Tier-1001"
network_cidr        = "10.10.1.0/24"
network_offering    = "DefaultIsolatedNetworkOfferingWithSourceNatService"

# Template et Service Offering
template_name       = "Debian 11"
service_offering    = "Rocky offer"

# SSH Keypair
ssh_keypair         = "vm-keys"

# Cluster
cluster_name        = "Focus-Cluster"
environment         = "prod"
instances_list      = ["master-01", "worker-02", "worker-03"]

# Load Balancer
lb_name             = "terraform-lb"
lb_algorithm        = "roundrobin"
lb_public_port      = 80
lb_private_port     = 80

# Firewall
firewall_protocol   = "tcp"
firewall_ports      = "80"
firewall_cidr       = "0.0.0.0/0"
internal_cidr       = "0.0.0.0/0"
EOF
```

### 3️⃣ Valider la Configuration

```bash
# Valider la syntaxe
terraform validate

# Afficher le plan d'exécution
terraform plan

# Sauvegarder le plan
terraform plan -out=tfplan
```

---

## Déploiement

### ⚠️ IMPORTANT : Avant de Déployer

1. **Vérifier les credentials** CloudStack
2. **Vérifier les ressources** (zone, template, offering)
3. **Vérifier l'espace disque** et les ressources disponibles
4. **Sauvegarder terraform.tfvars** (contient les secrets!)

### Déployer les Ressources

```bash
# Appliquer la configuration
terraform apply tfplan

# Ou sans fichier plan
terraform apply

# Appliquer sans confirmation
terraform apply -auto-approve
```

### Destruction des Ressources

```bash
# Afficher ce qui sera détruit
terraform plan -destroy

# Détruire les ressources
terraform destroy

# Détruire sans confirmation
terraform destroy -auto-approve
```

---

## Fichiers Détaillés

## 📄 providers.tf

### Contenu

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

### Description

- **Required Providers** : Déclare la dépendance au provider CloudStack v0.5.0
- **Provider Configuration** : Établit la connexion à l'API CloudStack

### Variables Utilisées

| Variable | Source | Description |
|----------|--------|-------------|
| `var.api_url` | `terraform.tfvars` | URL de l'API CloudStack |
| `var.api_key` | `terraform.tfvars` | Clé API pour authentification |
| `var.secret_key` | `terraform.tfvars` | Clé secrète pour authentification |

---

## 📄 variables.tf

### Contenu (Extrait)

```hcl
# API Configuration
variable "api_url" { type = string }
variable "api_key" { type = string; sensitive = true }
variable "secret_key" { type = string; sensitive = true }

# Zone et Network
variable "zone" { default = "Focus-Zone" }
variable "network_name" { default = "TERRAFORM-isolated" }
variable "network_cidr" { default = "10.0.0.0/24" }

# Instances
variable "instances_list" { 
  default = ["master-01", "worker-02", "worker-03"]
}

# Load Balancer
variable "lb_name" { default = "terraform-lb" }
variable "lb_algorithm" { default = "roundrobin" }
```

### Description

Ce fichier définit **toutes les variables** utilisées dans la configuration Terraform.

### Variables Principales

#### 🔐 API CloudStack

| Variable | Type | Requis | Défaut | Description |
|----------|------|--------|--------|-------------|
| `api_url` | string | ✅ | - | URL API CloudStack |
| `api_key` | string | ✅ | - | Clé API (sensible) |
| `secret_key` | string | ✅ | - | Clé secrète (sensible) |

#### 🗺️ Réseau

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `zone` | string | "Focus-Zone" | Nom de la zone CloudStack |
| `network_name` | string | "TERRAFORM-isolated" | Nom du réseau isolé |
| `network_cidr` | string | "10.0.0.0/24" | CIDR du réseau (ex: 10.10.1.0/24) |
| `network_offering` | string | "Default..." | Type d'offre réseau |

#### 🖥️ Instances

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `template_name` | string | "Rocky Linux 9" | Nom du template VM |
| `service_offering` | string | "Small Instance" | Offre de service (CPU/RAM) |
| `ssh_keypair` | string | "cloudstack-key" | Nom de la keypair SSH |
| `instances_list` | list(string) | `["master-01", ...]` | Liste des noms d'instances |

#### 🔄 Load Balancer

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `lb_name` | string | "terraform-lb" | Nom du LB |
| `lb_algorithm` | string | "roundrobin" | Algorithme (roundrobin/leastconn/source) |
| `lb_public_port` | number | 80 | Port public du LB |
| `lb_private_port` | number | 80 | Port backend des instances |

#### 🛡️ Sécurité

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `firewall_cidr` | string | "0.0.0.0/0" | CIDR autorisé (LB) |
| `internal_cidr` | string | "0.0.0.0/0" | CIDR interne |

---

## 📄 cloudstack_network.tf

### Contenu

```hcl
resource "cloudstack_network" "cluster" {
  name             = var.network_name
  cidr             = var.network_cidr
  zone             = var.zone
  network_offering = var.network_offering
}
```

### Description

Crée un **réseau isolé** où les instances Kubernetes seront connectées.

### Ressources Créées

| Ressource | ID Terraform | Type | Description |
|-----------|--------------|------|-------------|
| Réseau Isolé | `cloudstack_network.cluster` | Réseau | Réseau privé LAN (ex: 10.10.1.0/24) |

### Attributs Importants

```hcl
# Utilisés dans d'autres ressources
cloudstack_network.cluster.id     # ID du réseau (utilisé par instances)
cloudstack_network.cluster.name   # Nom du réseau
cloudstack_network.cluster.cidr   # CIDR du réseau
```

### Variables Utilisées

| Variable | Défaut | Description |
|----------|--------|-------------|
| `var.network_name` | "TERRAFORM-isolated" | Nom du réseau |
| `var.network_cidr` | "10.0.0.0/24" | Plage IP du réseau |
| `var.zone` | "Focus-Zone" | Zone CloudStack |
| `var.network_offering` | "Default..." | Type d'offre réseau |

---

## 📄 cloudstack_instance.tf

### Contenu

```hcl
resource "cloudstack_instance" "web" {
  for_each           = toset(var.instances_list)
  name               = each.value
  display_name       = "Web Server ${each.value}"
  service_offering   = var.service_offering
  template           = var.template_name
  zone               = var.zone
  keypair            = var.ssh_keypair
  expunge            = true
  user_data          = var.userdata_url != "" ? base64encode("...") : ""
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [cloudstack_network.cluster]
}
```

### Description

Crée les **instances VM** pour le cluster Kubernetes (Master + Workers).

### Ressources Créées

| Ressource | ID Terraform | Type | Quantité | Description |
|-----------|--------------|------|----------|-------------|
| Instance VM | `cloudstack_instance.web[master-01]` | Instance | N = nombre d'éléments dans `instances_list` | VMs Kubernetes |

### Attributs Clés

```hcl
# Attributs des instances créées
cloudstack_instance.web[*].id           # IDs des instances
cloudstack_instance.web[*].name         # Noms des instances
cloudstack_instance.web[*].ip_address   # IPs internes (réseau LAN)
cloudstack_instance.web[*].zone_id      # ID de la zone
```

### Variables Utilisées

| Variable | Défaut | Description |
|----------|--------|-------------|
| `var.instances_list` | `["master-01", "worker-02", "worker-03"]` | Noms des instances |
| `var.service_offering` | "Rocky offer" | Offering (CPU/RAM/Disk) |
| `var.template_name` | "Debian 11" | Template OS |
| `var.zone` | "Focus-Zone" | Zone CloudStack |
| `var.ssh_keypair` | "vm-keys" | Clé SSH pour accès |

### Paramètres Importants

- **for_each** : Boucle sur chaque élément de `instances_list`
- **expunge = true** : Supprime complètement les instances lors de la destruction
- **lifecycle** : Crée les nouvelles instances avant de détruire les anciennes
- **depends_on** : Attend la création du réseau

### Accès SSH

```bash
# Une fois déployées
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.x

# Où 10.10.1.x est l'IP interne de l'instance
```

---

## 📄 cloudstack_firewall.tf

### Contenu

```hcl
resource "cloudstack_security_group" "cluster" {
  name        = "${var.cluster_name}-sg"
  description = "Security group pour cluster ${var.cluster_name}"
}
```

### Description

Crée un **Security Group** pour contrôler le trafic réseau des instances.

### Ressources Créées

| Ressource | ID Terraform | Type | Description |
|-----------|--------------|------|-------------|
| Security Group | `cloudstack_security_group.cluster` | SG | Groupe de sécurité pour le cluster |

### Attributs Clés

```hcl
# Utilisé par les instances
cloudstack_security_group.cluster.id    # ID du SG
cloudstack_security_group.cluster.name  # Nom du SG
```

### Variables Utilisées

| Variable | Défaut | Description |
|----------|--------|-------------|
| `var.cluster_name` | "Focus-Cluster" | Nom du cluster |

### ⚠️ Note Importante

- Par défaut, CloudStack crée des règles par défaut dans chaque SG
- Pour restreindre le trafic, il faudrait ajouter des `cloudstack_security_group_rule` (actuellement non implémentées dans v0.5.0)

---

## 📄 cloudstack_template.tf

### Contenu

```hcl
data "cloudstack_template" "main" {
  filter {
    name   = "name"
    value  = var.template_name
  }
  template_filter = "executable"
}
```

### Description

**Data Source** qui recherche le template VM à utiliser pour créer les instances.

### Data Source Utilisée

| Data Source | ID Terraform | Type | Description |
|-------------|--------------|------|-------------|
| Template | `data.cloudstack_template.main` | Data | Lookup du template VM |

### Attributs Clés

```hcl
# Utilisés par les instances
data.cloudstack_template.main.id         # ID du template
data.cloudstack_template.main.name       # Nom du template
data.cloudstack_template.main.hypervisor # Type d'hypervisor (KVM)
```

### Variables Utilisées

| Variable | Défaut | Description |
|----------|--------|-------------|
| `var.template_name` | "Debian 11" | Nom du template à chercher |

### Exemple de Recherche

```bash
# Cherche un template nommé "Debian 11"
# Avec le filtre "executable" (template opérationnel)
```

---

## 📄 cloudstack_loadbalancer.tf

### Contenu

```hcl
# IP Publique
resource "cloudstack_ipaddress" "lb" {
  zone = var.zone
}

# Load Balancer Rule
resource "cloudstack_loadbalancer_rule" "http" {
  name           = "${var.lb_name}-http"
  algorithm      = var.lb_algorithm
  ip_address_id  = cloudstack_ipaddress.lb.id
  public_port    = var.lb_public_port
  private_port   = var.lb_private_port
  protocol       = "tcp"
  member_ids     = [for instance in cloudstack_instance.web : instance.id]
}
```

### Description

- **IP Publique** : Adresse IP publique pour accès externe
- **Load Balancer Rule** : Distribution de charge HTTP vers les instances

### Ressources Créées

| Ressource | ID Terraform | Type | Description |
|-----------|--------------|------|-------------|
| IP Publique | `cloudstack_ipaddress.lb` | IP publique | Adresse IP publique du LB |
| LB Rule HTTP | `cloudstack_loadbalancer_rule.http` | LB Rule | Distribution port 80 |

### Attributs Clés

```hcl
# IP publique
cloudstack_ipaddress.lb.ip_address      # Adresse IP publique (ex: 203.0.113.5)
cloudstack_ipaddress.lb.id              # ID de l'IP

# Load Balancer Rule
cloudstack_loadbalancer_rule.http.id    # ID de la règle
```

### Variables Utilisées

| Variable | Défaut | Description |
|----------|--------|-------------|
| `var.lb_name` | "terraform-lb" | Nom du LB |
| `var.lb_algorithm` | "roundrobin" | Algorithme (roundrobin/leastconn/source) |
| `var.lb_public_port` | 80 | Port public (accès externe) |
| `var.lb_private_port` | 80 | Port backend (instances internes) |
| `var.zone` | "Focus-Zone" | Zone CloudStack |

### Architecture du LB

```
Internet (0.0.0.0/0)
        │
        ▼
  IP Publique: 203.0.113.5
        │
        ▼ Port 80
  ┌─────────────────────┐
  │  Load Balancer      │
  │  (roundrobin)       │
  └─────────────────────┘
        │
    ┌───┼───┬────────┐
    │   │   │        │
    ▼   ▼   ▼        ▼
   Inst Inst Inst   Inst
   Port Port Port   Port
    80   80  80     80
```

### Exemple d'Utilisation

```bash
# Accès au service via LB
curl http://203.0.113.5:80

# Si HTTPS était configuré (port 443)
curl https://203.0.113.5:443
```

---

## 📄 outputs.tf

### Contenu (Extrait)

```hcl
output "web_instance_ips" {
  description = "IPs of web server instances"
  value = {
    for name, instance in cloudstack_instance.web :
    name => instance.ip_address
  }
}

output "load_balancer_ip" {
  description = "Public IP of the load balancer"
  value       = cloudstack_ipaddress.lb.ip_address
}

output "load_balancer_info" {
  description = "Load balancer configuration"
  value = {
    name           = var.lb_name
    algorithm      = var.lb_algorithm
    ip_address     = cloudstack_ipaddress.lb.ip_address
    public_port    = var.lb_public_port
    private_port   = var.lb_private_port
    members_count  = length(cloudstack_instance.web)
    members        = [for instance in cloudstack_instance.web : instance.name]
  }
}
```

### Description

Affiche les **valeurs de sortie** après le déploiement.

### Outputs Disponibles

| Output | Type | Description |
|--------|------|-------------|
| `web_instance_ips` | map(string) | IPs internes de chaque instance |
| `web_instance_ids` | map(string) | IDs CloudStack de chaque instance |
| `instances_summary` | object | Résumé complet du déploiement |
| `load_balancer_ip` | string | IP publique du LB |
| `load_balancer_id` | string | ID de l'IP publique |
| `load_balancer_info` | object | Configuration détaillée du LB |
| `web_service_url` | string | URL pour accès au service web |
| `kubernetes_api_url` | string | URL pour API Kubernetes (6443) |
| `ssh_access` | map(string) | Commandes SSH pour chaque instance |

### Exemple d'Utilisation

```bash
# Afficher tous les outputs
terraform output

# Afficher un output spécifique
terraform output load_balancer_ip
terraform output web_instance_ips
terraform output load_balancer_info

# Format JSON
terraform output -json
```

### Exemple de Sortie

```json
{
  "load_balancer_ip": "203.0.113.5",
  "web_instance_ips": {
    "master-01": "10.10.1.10",
    "worker-02": "10.10.1.11",
    "worker-03": "10.10.1.12"
  },
  "load_balancer_info": {
    "algorithm": "roundrobin",
    "ip_address": "203.0.113.5",
    "members": ["master-01", "worker-02", "worker-03"],
    "members_count": 3,
    "name": "terraform-lb",
    "private_port": 80,
    "public_port": 80
  }
}
```

---

## 📄 main.tf

### Contenu

```hcl
# Configuration générale et commentaires de déploiement
# ...
```

### Description

Fichier de configuration générale (actuellement minimal). Peut contenir :
- Commentaires du projet
- Configuration des outputs
- Paramètres de backend Terraform

---

## 📄 terraform.tfvars

### ⚠️ SÉCURITÉ

**NE PAS committer ce fichier** en version control (contient des secrets!)

### Contenu (Exemple)

```hcl
# === API CloudStack ===
api_url    = "http://192.168.18.20:8080/client/api"
api_key    = "hSzrvLYGRSafr_Pz2SSTCQwAX..."
secret_key = "QA2589c5O1vRDrzy7l2Ntb7Vsw..."

# === Zone et Réseau ===
zone                = "Focus-Zone"
network_name        = "Tier-1001"
network_cidr        = "10.10.1.0/24"
network_offering    = "DefaultIsolatedNetworkOfferingWithSourceNatService"

# === Template et Offering ===
template_name       = "Debian 11"
service_offering    = "Rocky offer"

# === SSH ===
ssh_keypair         = "vm-keys"

# === Cluster ===
cluster_name        = "Focus-Cluster"
environment         = "prod"
instances_list      = ["master-01", "worker-02", "worker-03"]

# === Load Balancer ===
lb_name             = "terraform-lb"
lb_algorithm        = "roundrobin"
lb_public_port      = 80
lb_private_port     = 80

# === Firewall ===
firewall_protocol   = "tcp"
firewall_ports      = "80"
firewall_cidr       = "0.0.0.0/0"
internal_cidr       = "0.0.0.0/0"
```

### .gitignore (Recommandé)

```bash
# Terraform
*.tfvars
*.tfvars.json
*.tfstate
*.tfstate.*
.terraform
.terraform.lock.hcl
crash.log
crash.*.log
```

---

## Commandes Utiles

### 🔍 Inspection

```bash
# Valider la configuration
terraform validate

# Formater les fichiers
terraform fmt -recursive

# Afficher le plan
terraform plan

# Sauvegarder le plan
terraform plan -out=tfplan

# Afficher un output spécifique
terraform output load_balancer_ip
terraform output -json
```

### 🚀 Déploiement

```bash
# Déployer avec confirmation
terraform apply

# Déployer avec fichier plan
terraform apply tfplan

# Déployer sans confirmation
terraform apply -auto-approve

# Déployer en parallèle (4 ressources simultanées)
terraform apply -parallelism=4
```

### 🧹 Destruction

```bash
# Plan de destruction
terraform plan -destroy

# Détruire avec confirmation
terraform destroy

# Détruire sans confirmation
terraform destroy -auto-approve

# Détruire une ressource spécifique
terraform destroy -target=cloudstack_instance.web
```

### 📊 État et Débogage

```bash
# Afficher l'état actuel
terraform show

# Afficher l'état en JSON
terraform show -json

# Lister toutes les ressources
terraform state list

# Afficher une ressource spécifique
terraform state show cloudstack_instance.web

# Afficher les logs de debug
TF_LOG=DEBUG terraform plan
TF_LOG=DEBUG terraform apply
```

---

## Workflow Complet de Déploiement

### 1. Préparation

```bash
# Cloner le repo ou accéder au répertoire
cd /media/sf_pfe_cloudstack/terraform

# Vérifier les credentials CloudStack
echo $CLOUDSTACK_API_URL
echo $CLOUDSTACK_API_KEY
echo $CLOUDSTACK_SECRET_KEY
```

### 2. Configuration

```bash
# Créer terraform.tfvars avec les bonnes valeurs
vi terraform.tfvars

# Vérifier les variables
terraform init
terraform validate
```

### 3. Planification

```bash
# Afficher ce qui sera créé
terraform plan

# Sauvegarder le plan pour approbation
terraform plan -out=tfplan
```

### 4. Déploiement

```bash
# Créer les ressources
terraform apply tfplan

# Attendre 5-10 minutes pour que les instances démarrent
```

### 5. Vérification

```bash
# Récupérer les IPs
terraform output web_instance_ips
terraform output load_balancer_ip

# Tester l'accès
curl http://$(terraform output -raw load_balancer_ip):80
```

### 6. Accès SSH

```bash
# SSH dans les instances
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.10  # Master
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.11  # Worker 1
```

### 7. Nettoyage (Si Nécessaire)

```bash
# Détruire toutes les ressources
terraform destroy -auto-approve

# Attendre la destruction complète (~2-3 minutes)
```

---

## Dépannage

### ❌ Erreur : Provider non trouvé

```
Error: Missing required provider

This configuration requires provider registry.terraform.io/cloudstack/cloudstack, but that provider isn't available.

Solution:
terraform init
```

### ❌ Erreur : Identifiants invalides

```
Error: Post "http://...": connection refused

Solution:
- Vérifier l'URL CloudStack
- Vérifier les credentials API_KEY et SECRET_KEY
- Vérifier la connexion réseau vers CloudStack
```

### ❌ Erreur : Template non trouvé

```
Error: No template found

Solution:
- Vérifier le nom exact du template dans CloudStack
- Utiliser: terraform output template_info
- Mettre à jour variable "template_name" dans terraform.tfvars
```

### ❌ Erreur : Zone invalide

```
Error: Invalid zone

Solution:
- Lister les zones dans CloudStack UI
- Mettre à jour variable "zone" dans terraform.tfvars
```

---

## Bonnes Pratiques

✅ **À Faire**

- Committer uniquement les fichiers `*.tf`
- Utiliser des variable defaults sensibles
- Valider avant chaque déploiement
- Sauvegarder les plans avant d'appliquer
- Documenter les changements

❌ **À Éviter**

- Committer les `terraform.tfvars` (secrets!)
- Modifier les ressources directement dans CloudStack UI
- Utiliser `-auto-approve` en production
- Déployer sans plan préalable
- Laisser les IP publiques inutilisées

---

## Support et Documentation

- 📖 [Terraform Docs](https://www.terraform.io/docs)
- ☁️ [CloudStack Provider](https://registry.terraform.io/providers/cloudstack/cloudstack/0.5.0)
- 🆘 [CloudStack API Docs](https://cloudstack.apache.org/docs/)

---

**Dernière mise à jour** : 16 avril 2026  
**Provider CloudStack** : 0.5.0  
**Terraform** : >= 1.0
