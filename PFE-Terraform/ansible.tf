# ===============================
# Ansible Inventory Generation
# ===============================

locals {
  # Séparer les masters et workers
  masters = {
    for name, instance in cloudstack_instance.web :
    name => instance.ip_address
    if startswith(name, "master")
  }
  
  workers = {
    for name, instance in cloudstack_instance.web :
    name => instance.ip_address
    if startswith(name, "worker")
  }
}

# Générer le fichier d'inventaire Ansible automatiquement avec bastion host
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"
  
  content = templatefile("${path.module}/templates/inventory.tpl", {
    bastion_ip = "192.168.21.10"  # IP du bastion/port-forwarding
    masters = {
      for name, instance in cloudstack_instance.web :
      name => instance.ip_address
      if startswith(name, "master")
    }
    workers = {
      for name, instance in cloudstack_instance.web :
      name => instance.ip_address
      if startswith(name, "worker")
    }
  })

  depends_on = [cloudstack_instance.web]
}

# Synchroniser l'inventaire vers le serveur Ansible distant via SCP
resource "null_resource" "sync_inventory_to_ansible" {
  # Établir une connexion SSH au serveur Ansible
  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = "ftsFTS123*"
    host        = var.ansible_host
    timeout     = "2m"
    agent       = false
  }

  # Exécuter la commande SCP pour tirer le fichier depuis Windows
  provisioner "remote-exec" {
    inline = [
      "echo 'Synchronisation de l'inventaire Ansible...'",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/vm_test.pem ubuntu@${var.windows_ip}:~/Desktop/pfe_cloudstack/ansible/inventory/hosts.ini ~/ansible/inventory/hosts.ini 2>/dev/null || echo 'SCP non disponible, utilisation de la méthode alternative'",
      "cat ~/ansible/inventory/hosts.ini"
    ]
    on_failure = continue
  }

  depends_on = [local_file.ansible_inventory]
}

# Alternative : écrire directement le contenu de l'inventaire sur le serveur
resource "null_resource" "write_inventory_direct" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = "ftsFTS123*"
    host        = var.ansible_host
    timeout     = "2m"
    agent       = false
  }

  # Créer le fichier directement via cat
  provisioner "file" {
    content      = local_file.ansible_inventory.content
    destination  = "/home/ubuntu/ansible/inventory/hosts.ini"
  }

  depends_on = [local_file.ansible_inventory]
}

# Output pour confirmer la génération
output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}

output "ansible_masters" {
  description = "Master nodes with their IPs"
  value       = local.masters
}

output "ansible_workers" {
  description = "Worker nodes with their IPs"
  value       = local.workers
}
