# ===============================
# Template Management pour CloudStack 0.5.0
# ===============================

# Template data lookup
data "cloudstack_template" "main" {
  filter {
    name   = "name"
    value  = var.template_name
  }
  template_filter = "executable"
}