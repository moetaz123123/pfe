# =======================================
# Network ACL - CloudStack Provider 0.5.0
# ACL assignée automatiquement via script
# =======================================

resource "cloudstack_network_acl" "cluster_acl" {
  name        = "${var.cluster_name}-acl"
  description = "Network ACL for Kubernetes cluster ${var.cluster_name}"
  vpc_id      = local.vpc_id
}

resource "cloudstack_network_acl_rule" "ingress_rules" {
  acl_id = cloudstack_network_acl.cluster_acl.id

  rule {
    action       = "allow"
    cidr_list    = ["0.0.0.0/0"]
    protocol     = "tcp"
    ports        = ["22"]
    traffic_type = "ingress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["0.0.0.0/0"]
    protocol     = "tcp"
    ports        = ["80"]
    traffic_type = "ingress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["0.0.0.0/0"]
    protocol     = "tcp"
    ports        = ["443"]
    traffic_type = "ingress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["10.0.0.0/8"]
    protocol     = "tcp"
    ports        = ["6443"]
    traffic_type = "ingress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["10.0.0.0/8"]
    protocol     = "tcp"
    ports        = ["2379-2380"]
    traffic_type = "ingress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["10.0.0.0/8"]
    protocol     = "tcp"
    ports        = ["10248-10250"]
    traffic_type = "ingress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["0.0.0.0/0"]
    protocol     = "tcp"
    ports        = ["30000-32767"]
    traffic_type = "ingress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["0.0.0.0/0"]
    protocol     = "tcp"
    ports        = ["9000"]
    traffic_type = "ingress"
  }
}

resource "cloudstack_network_acl_rule" "egress_rules" {
  acl_id = cloudstack_network_acl.cluster_acl.id

  rule {
    action       = "allow"
    cidr_list    = ["0.0.0.0/0"]
    protocol     = "tcp"
    ports        = ["1-65535"]
    traffic_type = "egress"
  }

  rule {
    action       = "allow"
    cidr_list    = ["0.0.0.0/0"]
    protocol     = "udp"
    ports        = ["1-65535"]
    traffic_type = "egress"
  }
}

# =======================================
# Assigner l'ACL au réseau automatiquement
# =======================================
resource "null_resource" "assign_acl_to_network" {
  depends_on = [
    cloudstack_network_acl.cluster_acl,
    cloudstack_network_acl_rule.ingress_rules,
    cloudstack_network_acl_rule.egress_rules
  ]

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/configure-acls.sh '${var.api_url}' '${var.api_key}' '${var.secret_key}' '${local.cluster_network_id}' '${local.vpc_id}' '${cloudstack_network_acl.cluster_acl.id}'"
  }

  # Détacher l'ACL lors de la destruction pour permettre sa suppression
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Note: ACL ${self.triggers.acl_id} remains in CloudStack. Manual cleanup may be needed if switching networks.'"
  }

  triggers = {
    acl_id     = cloudstack_network_acl.cluster_acl.id
    network_id = local.cluster_network_id
  }
}

output "firewall_configuration_guide" {
  value = {
    status       = "Network ACL configured and assigned automatically via Terraform"
    acl_name     = cloudstack_network_acl.cluster_acl.name
    acl_id       = cloudstack_network_acl.cluster_acl.id
    vpc_id       = local.vpc_id
    network_id   = local.cluster_network_id
    network_name = var.network_name
    network_cidr = var.network_cidr
    load_balancer_ip   = cloudstack_ipaddress.lb.ip_address
    kubernetes_api_url = "https://${cloudstack_ipaddress.lb.ip_address}:6443"
    web_service_url    = "http://${cloudstack_ipaddress.lb.ip_address}"
    master_node_ip     = local.web_instance_ips["master-01"]
    worker_nodes_ips   = [local.web_instance_ips["worker-02"], local.web_instance_ips["worker-03"]]
    ingress_rules = {
      ssh            = "22/tcp from 0.0.0.0/0"
      http           = "80/tcp from 0.0.0.0/0"
      https          = "443/tcp from 0.0.0.0/0"
      kubernetes_api = "6443/tcp from 10.0.0.0/8"
      etcd           = "2379-2380/tcp from 10.0.0.0/8"
      kubelet        = "10248-10250/tcp from 10.0.0.0/8"
      nodeport       = "30000-32767/tcp from 0.0.0.0/0"
      traefik        = "9000/tcp from 0.0.0.0/0"
    }
    egress_rules = {
      all_tcp = "1-65535/tcp to 0.0.0.0/0"
      all_udp = "1-65535/udp to 0.0.0.0/0"
    }
  }
}
