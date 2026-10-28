# Projets PFE

Ce dépôt regroupe deux projets liés à l'automatisation et au déploiement
d'infrastructure :

| Dossier | Description |
| --- | --- |
| [`ansiblepfe/`](./ansiblepfe/) | Projet Ansible organisé autour de playbooks, rôles, inventaires et variables de groupes pour automatiser la configuration et le déploiement. |
| [`PFE-Terraform/`](./PFE-Terraform/) | Configuration Terraform pour provisionner et gérer des ressources d'infrastructure CloudStack. |

## Structure

```text
.
├── ansiblepfe/
│   ├── ansible/
│   ├── group_vars/
│   ├── inventory/
│   ├── playbooks/
│   └── roles/
└── PFE-Terraform/
    ├── docs/
    ├── scripts/
    └── templates/
```

## Utilisation

Chaque sous-dossier est un projet indépendant et contient ses propres fichiers
de configuration et instructions. Consultez le README du projet concerné avant
de l'utiliser :

- [Documentation Ansible](./ansiblepfe/README.md)
- [Documentation Terraform](./PFE-Terraform/README.md)

Les prérequis, variables et commandes de déploiement peuvent différer entre les
deux projets. Vérifiez les fichiers d'exemple et la documentation avant toute
exécution.

## Sécurité

Ne publiez jamais de clés privées, mots de passe, fichiers de mots de passe
Ansible Vault, jetons ou variables Terraform contenant des secrets. Utilisez
des fichiers d'exemple sans valeurs sensibles et conservez les secrets dans un
gestionnaire de secrets ou dans des fichiers locaux exclus du contrôle de
version.
