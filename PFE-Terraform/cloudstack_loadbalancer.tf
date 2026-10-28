# ===============================
# Load Balancer Configuration - CloudStack 0.5.0
# ===============================

resource "cloudstack_ipaddress" "lb" {
  zone   = var.zone
  vpc_id = local.vpc_id

  depends_on = [cloudstack_instance.web]
}

resource "cloudstack_loadbalancer_rule" "http" {
  name          = "${var.lb_name}-http"
  algorithm     = var.lb_algorithm
  ip_address_id = cloudstack_ipaddress.lb.id
  network_id    = local.cluster_network_id
  public_port   = var.lb_public_port
  private_port  = var.lb_private_port
  protocol      = "tcp"
  member_ids    = [for instance in cloudstack_instance.web : instance.id]
}
# في cloudstack_loadbalancer.tf
resource "cloudstack_port_forward" "ssh_master" {
  ip_address_id = cloudstack_ipaddress.lb.id

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = 2201
    virtual_machine_id = cloudstack_instance.web["master-01"].id
  }
}

resource "cloudstack_port_forward" "ssh_worker02" {
  ip_address_id = cloudstack_ipaddress.lb.id

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = 2202
    virtual_machine_id = cloudstack_instance.web["worker-02"].id
  }
}

resource "cloudstack_port_forward" "ssh_worker03" {
  ip_address_id = cloudstack_ipaddress.lb.id

  forward {
    protocol           = "tcp"
    private_port       = 22
    public_port        = 2203
    virtual_machine_id = cloudstack_instance.web["worker-03"].id
  }
}