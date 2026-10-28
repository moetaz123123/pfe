# ===============================
# Outputs simplifiés
# ===============================

output "web_instance_ips" {
  description = "IPs of web server instances"
  value = {
    for name, instance in cloudstack_instance.web :
    name => instance.ip_address
  }
}

output "web_instance_ids" {
  description = "IDs of web server instances"
  value = {
    for name, instance in cloudstack_instance.web :
    name => instance.id
  }
}

output "instances_summary" {
  description = "Summary of deployed instances"
  value = {
    cluster_name   = var.cluster_name
    environment    = var.environment
    zone           = var.zone
    instances_list = var.instances_list
    deployed = {
      for name, instance in cloudstack_instance.web :
      name => {
        id        = instance.id
        ip        = instance.ip_address
        name      = instance.name
        role      = startswith(name, "master") ? "master" : "worker"
      }
    }
  }
}

output "ssh_access" {
  description = "SSH commands for accessing instances"
  value = {
    for name, instance in cloudstack_instance.web :
    name => "ssh -i <key> root@${instance.ip_address}"
  }
}

# ===============================
# Load Balancer Outputs
# ===============================

output "load_balancer_ip" {
  description = "Public IP of the load balancer"
  value       = cloudstack_ipaddress.lb.ip_address
}

output "load_balancer_id" {
  description = "ID of the load balancer IP address"
  value       = cloudstack_ipaddress.lb.id
}

output "load_balancer_info" {
  description = "Load balancer configuration information"
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
  description = "Web service URL via load balancer"
  value       = "http://${cloudstack_ipaddress.lb.ip_address}"
}

output "kubernetes_api_url" {
  description = "Kubernetes API URL via load balancer"
  value       = "https://${cloudstack_ipaddress.lb.ip_address}:6443"
}
