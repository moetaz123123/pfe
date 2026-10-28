variable "api_url" {
  type = string
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "zone" {
  type    = string
  default = "Focus-Zone"
}

variable "network_name" {
  type    = string
  default = "Tier-1001"
}

variable "network_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "network_offering" {
  type    = string
  default = "DefaultIsolatedNetworkOfferingWithSourceNatService"
}

variable "use_existing_network" {
  type    = bool
  default = true
}

variable "existing_network_id" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "template_name" {
  type    = string
  default = "testTemplate"
}

variable "template_url" {
  type    = string
  default = ""
}

variable "template_os_type" {
  type    = string
  default = "Ubuntu 22.04 LTS"
}

variable "template_hypervisor" {
  type    = string
  default = "KVM"
}

variable "template_format" {
  type    = string
  default = "QCOW2"
}

variable "service_offering" {
  type    = string
  default = "Small Instance"
}

variable "ssh_keypair" {
  type    = string
  default = "cloudstack-key"
}

variable "userdata_url" {
  type    = string
  default = ""
}

variable "cluster_name" {
  type    = string
  default = "Focus-Cluster"
}

variable "environment" {
  type    = string
  default = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "instances_list" {
  type    = list(string)
  default = ["master-01", "worker-02", "worker-03"]
}

variable "lb_name" {
  type    = string
  default = "terraform-lb"
}

variable "lb_algorithm" {
  type    = string
  default = "roundrobin"
}

variable "lb_public_port" {
  type    = number
  default = 80
}

variable "lb_private_port" {
  type    = number
  default = 80
}

variable "firewall_protocol" {
  type    = string
  default = "tcp"
}

variable "firewall_ports" {
  type    = string
  default = "80"
}

variable "firewall_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "internal_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
