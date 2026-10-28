# ============================================================================
# MAIN CONFIGURATION FILE - Web Deployment on CloudStack
# ============================================================================
#
# This configuration deploys a web application infrastructure on CloudStack:
# - 4 web server instances (web-01 through web-04)
# - Load balancer with HTTP (port 80) support
# - Isolated network (TERRAFORM-isolated on 10.0.0.0/24)
# - Debian 11 x86_64 template
#
# ACTUAL RESOURCE DEFINITIONS:
# - Providers:  providers.tf
# - Variables:  variables.tf
# - Compute:    cloudstack_instance.tf
# - Load Balancer: cloudstack_loadbalancer.tf
# - Firewall/Security: cloudstack_firewall.tf
# - Network/Zone: cloudstack_network.tf
# - Template: cloudstack_template.tf
# - Outputs: outputs.tf
#
# QUICK START:
# 1. cp terraform.tfvars.example terraform.tfvars
# 2. Edit terraform.tfvars with your CloudStack credentials
# 3. terraform init
# 4. terraform validate
# 5. terraform plan
# 6. terraform apply
#
# ============================================================================