# 📄 cloudstack_instance.tf - Instances VM du Cluster

## 📌 Vue d'ensemble

Ce fichier crée les **instances VM** (Master + Workers) qui formeront le cluster Kubernetes.

## 📋 Contenu Complet

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

  user_data = var.userdata_url != "" ? base64encode("#!/bin/bash\ncurl -s ${var.userdata_url} | bash") : ""

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    cloudstack_network.cluster
  ]
}
```

## 🔧 Ressource Détaillée

### Bloc `resource "cloudstack_instance" "web"`

Crée une instance VM dans CloudStack.

#### Arguments Principaux

| Argument | Type | Requis | Défaut | Description |
|----------|------|--------|--------|-------------|
| `name` | string | ✅ | - | Nom unique de l'instance (ex: master-01) |
| `display_name` | string | ❌ | `name` | Nom affiché dans l'interface |
| `service_offering` | string | ✅ | - | Offre de service (CPU, RAM, Disk) |
| `template` | string | ✅ | - | Nom du template VM à utiliser |
| `zone` | string | ✅ | - | Zone CloudStack |
| `keypair` | string | ✅ | - | Nom de la clé SSH pour accès |
| `expunge` | bool | ❌ | false | true = supprime complètement à la destruction |
| `user_data` | string | ❌ | - | Script cloud-init en base64 |

## 🔄 Boucle `for_each`

La configuration utilise `for_each` pour créer **plusieurs instances** :

```hcl
for_each = toset(var.instances_list)
```

### Exemple

```hcl
# terraform.tfvars
instances_list = ["master-01", "worker-02", "worker-03"]

# Crée 3 ressources :
# cloudstack_instance.web["master-01"]
# cloudstack_instance.web["worker-02"]
# cloudstack_instance.web["worker-03"]
```

### Accès aux Instances

```hcl
# Toutes les instances
cloudstack_instance.web[*].id
cloudstack_instance.web[*].ip_address

# Instance spécifique
cloudstack_instance.web["master-01"].id
cloudstack_instance.web["master-01"].ip_address

# Boucle sur les instances
for instance in cloudstack_instance.web : instance.ip_address
```

## 📌 Attributs de Sortie

Après création, chaque instance a :

| Attribut | Type | Description | Exemple |
|----------|------|-------------|---------|
| `id` | string | ID CloudStack | abc123def456 |
| `name` | string | Nom de l'instance | master-01 |
| `display_name` | string | Nom affiché | Web Server master-01 |
| `ip_address` | string | IP interne (LAN) | 10.10.1.10 |
| `zone_id` | string | ID de la zone | zone-123 |
| `service_offering_id` | string | ID de l'offering | offering-456 |
| `template_id` | string | ID du template | template-789 |
| `state` | string | État de l'instance | Running/Stopped |

## 🧬 Configuration du Cycle de Vie

### Bloc `lifecycle`

```hcl
lifecycle {
  create_before_destroy = true
}
```

**Effet** : 
- Crée la nouvelle instance AVANT de supprimer l'ancienne
- Évite les interruptions de service pendant les mises à jour
- Utile pour les redéploiements

**Alternatives** :

```hcl
# Ignorer les changements de user_data (ne pas redéployer)
lifecycle {
  ignore_changes = [user_data]
}

# Prévenir les destructions accidentelles
lifecycle {
  prevent_destroy = true
}

# Utiliser les deux
lifecycle {
  create_before_destroy = true
  ignore_changes        = [user_data]
}
```

## 🔗 Dépendances

### Bloc `depends_on`

```hcl
depends_on = [
  cloudstack_network.cluster
]
```

**Effet** :
- Terraform attendra la création du réseau avant créer les instances
- Les instances seront connectées à ce réseau

## 📦 User Data (Cloud-Init)

### Contenu

```hcl
user_data = var.userdata_url != "" ? 
  base64encode("#!/bin/bash\ncurl -s ${var.userdata_url} | bash") : ""
```

### Fonctionnement

1. **Si `var.userdata_url` est défini** :
   - Crée un script qui télécharge et exécute le script distant
   - Encodé en base64 pour CloudStack

2. **Si `var.userdata_url` est vide** :
   - Pas de script cloud-init

### Exemple d'Utilisation

```hcl
# terraform.tfvars
userdata_url = "https://example.com/init-script.sh"

# Ou laissez vide pour pas d'initialisation
userdata_url = ""
```

### Script Exemple

```bash
#!/bin/bash
set -e

# Mise à jour du système
apt-get update
apt-get upgrade -y

# Installation des packages
apt-get install -y \
  curl \
  wget \
  git \
  docker.io

# Démarrage des services
systemctl start docker
systemctl enable docker

echo "Instance initialisée !"
```

## 📊 Exemple : Configuration Complete

### Variables

```hcl
# terraform.tfvars
instances_list   = ["master-01", "worker-02", "worker-03", "worker-04"]
service_offering = "Rocky offer"          # 4 CPU, 8 GB RAM
template_name    = "Debian 11"            # Ubuntu 20.04 LTS
zone             = "Focus-Zone"
ssh_keypair      = "vm-keys"
userdata_url     = ""                     # Pas d'init script
```

### Instances Créées

```
┌─────────────────────────────────────────────────────────────┐
│                  Instances Déployées                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. master-01                  2. worker-02                 │
│     IP: 10.10.1.10                IP: 10.10.1.11            │
│     RAM: 8 GB                      RAM: 8 GB                │
│     CPU: 4 cores                   CPU: 4 cores             │
│     Disk: 50 GB                    Disk: 50 GB              │
│     OS: Debian 11                  OS: Debian 11            │
│                                                             │
│  3. worker-03                  4. worker-04                 │
│     IP: 10.10.1.12                IP: 10.10.1.13            │
│     (Même configuration)           (Même configuration)     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🖥️ Accès SSH

### Commandes SSH

```bash
# Master
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.10

# Workers
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.11
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.12
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.13
```

### Troubleshooting SSH

```bash
# Vérifier la clé
ls -la ~/.ssh/vm-keys.pem
chmod 600 ~/.ssh/vm-keys.pem

# Test de connexion
ssh -v -i ~/.ssh/vm-keys.pem root@10.10.1.10

# Vérifier les IPs créées
terraform output web_instance_ips
```

## 🔄 Opérations Courantes

### Ajouter une Instance

```hcl
# terraform.tfvars - AVANT
instances_list = ["master-01", "worker-02", "worker-03"]

# terraform.tfvars - APRÈS
instances_list = ["master-01", "worker-02", "worker-03", "worker-04"]

# Appliquer
terraform apply
```

### Supprimer une Instance

```hcl
# terraform.tfvars - AVANT
instances_list = ["master-01", "worker-02", "worker-03", "worker-04"]

# terraform.tfvars - APRÈS (supprimer worker-04)
instances_list = ["master-01", "worker-02", "worker-03"]

# Appliquer
terraform apply
```

### Redéployer une Instance

```bash
# Forcer la recréation d'une instance spécifique
terraform destroy -target='cloudstack_instance.web["worker-02"]'
terraform apply -target='cloudstack_instance.web["worker-02"]'

# Ou utiliser taint
terraform taint 'cloudstack_instance.web["worker-02"]'
terraform apply
```

## 📋 Outputs Associés

Les instances créées sont référencées dans [outputs.tf](../outputs.tf) :

```hcl
output "web_instance_ips" {
  value = {
    for name, instance in cloudstack_instance.web :
    name => instance.ip_address
  }
}

output "web_instance_ids" {
  value = {
    for name, instance in cloudstack_instance.web :
    name => instance.id
  }
}

output "ssh_access" {
  value = {
    for name, instance in cloudstack_instance.web :
    name => "ssh -i <key> root@${instance.ip_address}"
  }
}
```

## ✅ Validation

### Vérifier les Instances

```bash
# Lister toutes les instances
terraform state list | grep cloudstack_instance

# Afficher une instance spécifique
terraform state show 'cloudstack_instance.web["master-01"]'

# Récupérer les IPs
terraform output web_instance_ips
```

### Erreurs Courantes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `Invalid service_offering` | Offering n'existe pas | Vérifier le nom dans CloudStack |
| `Invalid template` | Template n'existe pas | Vérifier le nom du template |
| `Invalid zone` | Zone n'existe pas | Vérifier le nom de la zone |
| `Invalid keypair` | Clé SSH non créée | Créer la keypair dans CloudStack |
| `Insufficient capacity` | Pas de ressources disponibles | Attendre ou réduire les instances |

## 🔐 Sécurité

### Recommandations

✅ **À Faire**

- Utiliser des passwords forts
- Restreindre l'accès SSH avec Security Groups
- Mettre à jour régulièrement les templates
- Utiliser des user data sécurisés
- Monitorer les instances

❌ **À Éviter**

- Déployer avec des IPs publiques non sécurisées
- Utiliser des mots de passe par défaut
- Laisser SSH ouvert à Internet (0.0.0.0/0)
- Stocker des secrets dans user_data

## 🔗 Fichiers Liés

- [cloudstack_network.tf](./cloudstack_network.tf) - Réseau pour les instances
- [cloudstack_firewall.tf](./cloudstack_firewall.tf) - Security Groups
- [cloudstack_template.tf](./cloudstack_template.tf) - Template lookup
- [variables.tf](./variables.tf) - Définition des variables
- [outputs.tf](./outputs.tf) - Affichage des IPs et IDs

## 🎯 Résumé

| Élément | Valeur |
|--------|--------|
| **Type de Ressource** | cloudstack_instance |
| **Nombre d'Instances** | Variable (par défaut 3) |
| **Boucle** | for_each sur instances_list |
| **Dépendances** | cloudstack_network.cluster |
| **Accès** | SSH via clé publique |

---

**Version** : 1.0  
**Date** : 16 avril 2026  
**Statut** : ✅ Validé
