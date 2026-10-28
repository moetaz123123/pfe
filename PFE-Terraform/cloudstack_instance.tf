# ===============================
# Instance Configuration - CloudStack 0.5.0
# Advanced Zone - sans Security Groups
# ===============================

resource "cloudstack_instance" "web" {
  for_each         = toset(var.instances_list)
  name             = each.value
  display_name     = "Web Server ${each.value}"
  service_offering = var.service_offering
  template         = var.template_name
  zone             = var.zone
  network_id       = local.cluster_network_id
  keypair          = var.ssh_keypair
  expunge          = true

  user_data = var.userdata_url != "" ? base64encode("#!/bin/bash\ncurl -s ${var.userdata_url} | bash") : ""

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    cloudstack_network.cluster,
    cloudstack_network_acl_rule.ingress_rules,
    cloudstack_network_acl_rule.egress_rules
  ]
}
