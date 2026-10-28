# ===============================
# Network Configuration - avec VPC
# Advanced Zone - Network ACL pour sécurité
# ===============================

resource "cloudstack_network" "cluster" {
  count            = var.use_existing_network ? 0 : 1
  name             = var.network_name
  cidr             = var.network_cidr
  zone             = var.zone
  network_offering = var.network_offering

  tags = {
    Name        = var.network_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # ✅ prevent_destroy supprimé pour permettre terraform destroy
}

locals {
  cluster_network_id = var.use_existing_network ? var.existing_network_id : cloudstack_network.cluster[0].id
  vpc_id             = var.vpc_id
  web_instance_ips   = { for name, instance in cloudstack_instance.web : name => instance.ip_address }
}

output "cluster_network_id" {
  value       = local.cluster_network_id
  description = "ID of the cluster network"
}
