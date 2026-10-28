# 📄 cloudstack_loadbalancer.tf - Load Balancer et IP Publique

## 📌 Vue d'ensemble

Ce fichier crée :
- **IP Publique** : Adresse IP externe pour accès depuis Internet
- **Load Balancer Rule** : Distribution de charge HTTP vers les instances

## 📋 Contenu Complet

```hcl
# IP Publique pour le Load Balancer
resource "cloudstack_ipaddress" "lb" {
  zone = var.zone
}

# Load Balancer Rule - HTTP (Port 80)
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

## 🔧 Ressource 1 : IP Publique

### Bloc `resource "cloudstack_ipaddress" "lb"`

Crée une adresse IP publique pour accès externe.

#### Arguments

| Argument | Type | Requis | Description |
|----------|------|--------|-------------|
| `zone` | string | ✅ | Zone CloudStack |

#### Attributs Générés

| Attribut | Type | Description | Exemple |
|----------|------|-------------|---------|
| `id` | string | ID de l'adresse IP | ip-abc123 |
| `ip_address` | string | Adresse IP publique | 203.0.113.5 |
| `zone_id` | string | ID de la zone | zone-123 |

### Exemple

```bash
# Après déploiement
terraform output load_balancer_ip
# Output: 203.0.113.5
```

## 🔧 Ressource 2 : Load Balancer Rule

### Bloc `resource "cloudstack_loadbalancer_rule" "http"`

Crée une règle de load balancer pour distribuer le trafic.

#### Arguments

| Argument | Type | Requis | Description |
|----------|------|--------|-------------|
| `name` | string | ✅ | Nom de la règle (ex: terraform-lb-http) |
| `algorithm` | string | ✅ | Algorithme de distribution |
| `ip_address_id` | string | ✅ | ID de l'IP publique |
| `public_port` | number | ✅ | Port public (accès externe) |
| `private_port` | number | ✅ | Port privé (instances backend) |
| `protocol` | string | ❌ | Protocole (tcp, udp) |
| `member_ids` | list(string) | ✅ | IDs des instances (members) |

### Algorithmes de Distribution

| Algorithme | Comportement | Cas d'Usage |
|-----------|-------------|-----------|
| `roundrobin` | Distribue cycliquement | Par défaut, recommandé |
| `leastconn` | Moins de connexions actives | Sessions longues |
| `source` | IP source du client | Sessions persistantes |

### Exemple

```hcl
# terraform.tfvars
lb_algorithm    = "roundrobin"
lb_public_port  = 80      # Internet → Port 80
lb_private_port = 80      # Instances → Port 80
```

## 📊 Architecture du Load Balancer

```
┌──────────────────────────────────────────────────────────────┐
│                      Internet                                │
│                    203.0.113.5:80                            │
│                    (Adresse IP Publique)                     │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
                 ┌──────────────────┐
                 │  Load Balancer   │
                 │  (roundrobin)    │
                 │  Algorithme      │
                 │  Distribution    │
                 └────────┬─────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
   ┌──────────┐     ┌──────────┐     ┌──────────┐
   │ Master   │     │ Worker-1 │     │ Worker-2 │
   │:80       │     │:80       │     │:80       │
   │10.10.1.10│     │10.10.1.11│     │10.10.1.12│
   └──────────┘     └──────────┘     └──────────┘
       (Interne Network LAN)
```

## 🔄 Flux de Requête

### Exemple : Requête HTTP

```
1. Client Internet
   $ curl http://203.0.113.5/

2. Adresse IP Publique reçoit la requête
   IP: 203.0.113.5 Port: 80

3. Load Balancer distribue (roundrobin)
   1ère req → master-01:80      (10.10.1.10:80)
   2ème req → worker-01:80      (10.10.1.11:80)
   3ème req → worker-02:80      (10.10.1.12:80)
   4ème req → master-01:80      (10.10.1.10:80)  [cycle repeat]

4. Instance répond
   Response via même chemin retour

5. Client reçoit la réponse
```

## 📋 Variables Utilisées

```hcl
# terraform.tfvars
lb_name             = "terraform-lb"
lb_algorithm        = "roundrobin"
lb_public_port      = 80
lb_private_port     = 80
zone                = "Focus-Zone"
```

## 📌 Outputs Associés

```hcl
output "load_balancer_ip" {
  value = cloudstack_ipaddress.lb.ip_address
}

output "load_balancer_info" {
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

output "web_service_url" {
  value = "http://${cloudstack_ipaddress.lb.ip_address}:${var.lb_public_port}"
}
```

## 🚀 Utilisation

### Accéder au Service

```bash
# Obtenir l'IP du LB
LB_IP=$(terraform output -raw load_balancer_ip)

# Accéder via HTTP
curl http://$LB_IP
curl http://$LB_IP/api
curl http://$LB_IP:80

# Depuis navigateur
http://203.0.113.5/
```

### Afficher la Configuration

```bash
# Afficher tous les LB outputs
terraform output load_balancer_info

# Output:
{
  "algorithm" = "roundrobin"
  "ip_address" = "203.0.113.5"
  "members" = ["master-01", "worker-02", "worker-03"]
  "members_count" = 3
  "name" = "terraform-lb"
  "private_port" = 80
  "public_port" = 80
}
```

## 🔐 Sécurité

### Configuration Sécurisée

✅ **À Faire**

- Utiliser HTTPS (port 443) en production
- Restreindre les ports autorisés via Firewall
- Utiliser des certificats SSL/TLS
- Monitorer le trafic
- Implémenter rate limiting

❌ **À Éviter**

- Laisser HTTP en production (pas de chiffrement)
- Ouvrir tous les ports à Internet
- Utiliser les ports par défaut
- Négliger la sécurité du LB

## 🔄 Modifications

### Changer l'Algorithme

```hcl
# terraform.tfvars - AVANT
lb_algorithm = "roundrobin"

# terraform.tfvars - APRÈS
lb_algorithm = "leastconn"

# Appliquer
terraform apply
```

### Changer les Ports

```hcl
# terraform.tfvars - AVANT
lb_public_port  = 80
lb_private_port = 80

# terraform.tfvars - APRÈS
lb_public_port  = 8080   # Accès externe sur 8080
lb_private_port = 80     # Instances écoutent sur 80

# Appliquer
terraform apply
```

### Ajouter un Second LB (HTTPS)

```hcl
# cloudstack_loadbalancer.tf
resource "cloudstack_loadbalancer_rule" "https" {
  name           = "${var.lb_name}-https"
  algorithm      = var.lb_algorithm
  ip_address_id  = cloudstack_ipaddress.lb.id
  public_port    = 443
  private_port   = 443
  protocol       = "tcp"
  member_ids     = [for instance in cloudstack_instance.web : instance.id]
}
```

## 📊 Monitoring

### Afficher le Trafic

```bash
# SSH dans une instance
ssh -i ~/.ssh/vm-keys.pem root@10.10.1.10

# Vérifier les connexions actives
netstat -an | grep :80 | wc -l

# Afficher les clients connectés
netstat -an | grep :80 | grep ESTABLISHED

# Surveiller en temps réel
watch 'netstat -an | grep :80 | wc -l'
```

## ❌ Erreurs Courantes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `Invalid ip_address_id` | IP n'existe pas | S'assurer que `cloudstack_ipaddress.lb` est créée |
| `Invalid member_ids` | Instances n'existent pas | S'assurer que `cloudstack_instance.web` est déployée |
| `Port already in use` | Port déjà utilisé | Choisir un autre port |
| `Connection refused` | Service n'écoute pas | Vérifier que le service écoute sur le bon port |

## 🔗 Fichiers Liés

- [cloudstack_instance.tf](./cloudstack_instance.tf) - Instances (members du LB)
- [cloudstack_firewall.tf](./cloudstack_firewall.tf) - Security Groups
- [outputs.tf](./outputs.tf) - Affichage de l'IP du LB
- [variables.tf](./variables.tf) - Configuration du LB

## 🎯 Résumé

| Élément | Valeur |
|--------|--------|
| **IP Publique** | cloudstack_ipaddress.lb |
| **LB Rule** | cloudstack_loadbalancer_rule.http |
| **Algorithme Défaut** | roundrobin |
| **Port Public** | 80 |
| **Port Backend** | 80 |
| **Membres** | Instances du cluster |

---

**Version** : 1.0  
**Date** : 16 avril 2026  
**Statut** : ✅ Validé
