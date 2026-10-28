# 📄 cloudstack_network.tf - Configuration du Réseau Isolé

## 📌 Vue d'ensemble

Ce fichier crée un **réseau isolé** (LAN privé) où les instances Kubernetes seront connectées.

## 📋 Contenu Complet

```hcl
resource "cloudstack_network" "cluster" {
  name             = var.network_name
  cidr             = var.network_cidr
  zone             = var.zone
  network_offering = var.network_offering
}
```

## 🔧 Ressource Détaillée

### Bloc `resource "cloudstack_network" "cluster"`

Crée un réseau isolé dans CloudStack.

#### Arguments

| Argument | Type | Requis | Défaut | Description |
|----------|------|--------|--------|-------------|
| `name` | string | ✅ | - | Nom du réseau (ex: Tier-1001) |
| `cidr` | string | ✅ | - | Plage CIDR du réseau (ex: 10.10.1.0/24) |
| `zone` | string | ✅ | - | Zone CloudStack |
| `network_offering` | string | ✅ | - | Type d'offre réseau |

## 📊 Configuration Réseau

### Variables Utilisées

```hcl
# terraform.tfvars
zone                = "Focus-Zone"
network_name        = "Tier-1001"
network_cidr        = "10.10.1.0/24"
network_offering    = "DefaultIsolatedNetworkOfferingWithSourceNatService"
```

### Types d'Offres Réseau

| Offre | Type | Cas d'Usage | Source NAT |
|-------|------|------------|-----------|
| `DefaultIsolatedNetworkOfferingWithSourceNatService` | Isolé | Réseaux privés avec accès Internet | ✅ |
| `DefaultIsolatedNetworkOffering` | Isolé | Réseaux privés sans NAT | ❌ |
| `DefaultVpcOffering` | VPC | VPC avec gestion d'adresses | ✅ |

### Exemple de Plages CIDR

```
Petite déploiement :
  10.0.0.0/24      → 254 IPs disponibles

Moyen :
  10.10.1.0/23     → 510 IPs disponibles

Grande :
  10.0.0.0/16      → 65534 IPs disponibles
```

## 🏗️ Architecture du Réseau

```
┌───────────────────────────────────────┐
│        Zone: Focus-Zone              │
├───────────────────────────────────────┤
│                                       │
│  ┌─────────────────────────────────┐ │
│  │  Réseau Isolé (LAN Privé)      │ │
│  │  Name: Tier-1001               │ │
│  │  CIDR: 10.10.1.0/24            │ │
│  │                                 │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │ Master: 10.10.1.10       │  │ │
│  │  │ Worker1: 10.10.1.11      │  │ │
│  │  │ Worker2: 10.10.1.12      │  │ │
│  │  │ Worker3: 10.10.1.13      │  │ │
│  │  └──────────────────────────┘  │ │
│  │                                 │ │
│  │  Gateway: 10.10.1.1            │ │
│  │  DNS: 10.10.1.1                │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │  Internet (via NAT)             │ │
│  │  IP Publique: 203.0.113.5       │ │
│  └─────────────────────────────────┘ │
│                                       │
└───────────────────────────────────────┘
```

## 🔄 Allocation d'IPs

Pour `10.10.1.0/24` :

```
10.10.1.1       → Gateway/DNS (réservé)
10.10.1.2-10    → Adresses réservées (dhcp pool)
10.10.1.10      → master-01
10.10.1.11      → worker-02
10.10.1.12      → worker-03
10.10.1.13-254  → Disponible pour autres ressources
```

## 📌 Attributs de Sortie

Après création, le réseau a :

| Attribut | Type | Description | Exemple |
|----------|------|-------------|---------|
| `id` | string | ID CloudStack du réseau | net-abc123 |
| `name` | string | Nom du réseau | Tier-1001 |
| `cidr` | string | Plage CIDR | 10.10.1.0/24 |
| `zone_id` | string | ID de la zone | zone-123 |
| `gateway` | string | IP de la passerelle | 10.10.1.1 |
| `dns1` | string | Serveur DNS primaire | 10.10.1.1 |

## 🔗 Utilisation dans Autres Ressources

### Instances

```hcl
# Les instances utilisent ce réseau
resource "cloudstack_instance" "web" {
  # ...
  depends_on = [cloudstack_network.cluster]
}
```

### Load Balancer

```hcl
# Le LB distribue le trafic vers les instances du réseau
# (Indirectement via les instances)
```

## 🚀 Commandes Utiles

```bash
# Afficher le réseau créé
terraform state show cloudstack_network.cluster

# Récupérer l'ID du réseau
terraform output -raw network_id

# Afficher le réseau en JSON
terraform state show -json cloudstack_network.cluster
```

## ✅ Validation

### Vérifier la Configuration

```bash
# Avant le déploiement
terraform plan

# Vérifier le réseau dans CloudStack UI
# CloudStack UI → Network → Tier-1001

# Vérifier les instances connectées
terraform output web_instance_ips
```

### Erreurs Courantes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `Invalid zone` | Zone n'existe pas | Vérifier le nom dans CloudStack |
| `Invalid network_offering` | Offering n'existe pas | Lister les offerings disponibles |
| `CIDR already in use` | CIDR utilisé ailleurs | Choisir une autre plage CIDR |
| `Invalid CIDR` | Format CIDR incorrect | Utiliser format: X.X.X.X/XX |

## 📋 Diagnostics

### Vérifier la Connectivité Réseau

```bash
# SSH dans une instance
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.10

# Une fois connecté :
# Vérifier l'IP
ip addr show

# Vérifier la passerelle
ip route show

# Vérifier DNS
cat /etc/resolv.conf

# Tester la connectivité
ping 10.10.1.11  # Autre instance
ping 8.8.8.8     # Internet
```

### Vérifier le Réseau dans CloudStack

```bash
# CloudStack UI
Administration → Networks → Tier-1001

# Afficher :
# - Instances connectées
# - Adresses IP allouées
# - Statistiques réseau
```

## 🔐 Sécurité

### Isolation du Réseau

✅ **Sécurisation Existante**

- Réseau isolé (pas d'accès direct depuis Internet)
- Instances privées (IPs internes uniquement)
- Trafic sortant via NAT (IP publique du LB)

### Recommandations

✅ **À Faire**

- Utiliser des CIDR standards (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- Documenter la plage CIDR utilisée
- Utiliser des Network ACLs pour restreindre le trafic
- Monitorer le trafic réseau

❌ **À Éviter**

- Utiliser des CIDR publics
- Laisser le trafic réseau non sécurisé
- Connecter des réseaux conflictuels

## 🔄 Modifications du Réseau

### Changer le CIDR

⚠️ **ATTENTION** : Recréera le réseau entièrement!

```hcl
# terraform.tfvars - AVANT
network_cidr = "10.10.1.0/24"

# terraform.tfvars - APRÈS
network_cidr = "10.10.2.0/24"

# Cela va :
# 1. Détruire le réseau actuel et les instances!
# 2. Créer un nouveau réseau
# 3. Créer de nouvelles instances
```

### Ajouter un Sous-réseau

Pour ajouter un second réseau, créez une nouvelle ressource :

```hcl
resource "cloudstack_network" "secondary" {
  name             = "secondary-net"
  cidr             = "10.10.2.0/24"
  zone             = var.zone
  network_offering = var.network_offering
}
```

## 📊 Monitoring

### Afficher l'Utilisation du Réseau

```bash
# SSH dans une instance
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.10

# Une fois connecté :
# Afficher les interfaces
ip link

# Afficher les statistiques
ip -s link

# Afficher les connexions actives
netstat -an | grep ESTABLISHED
```

## 🎯 Résumé

| Élément | Valeur |
|--------|--------|
| **Type de Ressource** | cloudstack_network |
| **Type de Réseau** | Réseau Isolé (LAN Privé) |
| **CIDR Défaut** | 10.10.1.0/24 |
| **Instances Connectées** | Master + 3 Workers |
| **Accès Internet** | Via NAT (IP publique du LB) |

---

**Version** : 1.0  
**Date** : 16 avril 2026  
**Statut** : ✅ Validé
