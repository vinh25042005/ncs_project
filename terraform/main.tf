# ==============================================================================
# NCS PROJECT: MAIN TERRAFORM ORCHESTRATION
# Architecture: pfSense Edge Gateway, Upstream Kubernetes v1.31, Wazuh SIEM
# ==============================================================================

# 1. Module Mạng Multi-AZ (VPC, Subnet WAN, Subnet Private K8s A&B, Subnet Mgmt)
module "network" {
  source              = "./modules/network"
  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_wan_cidr     = var.public_wan_cidr
  private_k8s_cidr    = var.private_k8s_cidr
  mgmt_cidr           = var.mgmt_cidr
  availability_zone   = var.availability_zone
  availability_zone_b = var.availability_zone_b
}

# 2. Module Security Groups (pfSense SG, K8s Private SG, Wazuh SG, Rancher SG)
module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  vpc_cidr     = var.vpc_cidr
  admin_cidr   = var.admin_cidr
}

# 3. Module Compute (pfSense Gateway, K8s Master & Multi-AZ Workers)
module "compute" {
  source                   = "./modules/compute"
  project_name             = var.project_name
  key_name                 = var.key_name
  public_wan_subnet_id     = module.network.public_wan_subnet_id
  private_k8s_subnet_id    = module.network.private_k8s_subnet_id
  private_k8s_subnet_b_id  = module.network.private_k8s_subnet_b_id
  mgmt_subnet_id           = module.network.mgmt_subnet_id
  pfsense_sg_id            = module.security.pfsense_sg_id
  k8s_sg_id                = module.security.k8s_sg_id
  wazuh_sg_id              = module.security.wazuh_sg_id
  rancher_sg_id            = module.security.rancher_sg_id
  pfsense_ami_id           = var.pfsense_ami_id
  pfsense_instance_type    = var.pfsense_instance_type
  pfsense_lan_ip           = var.pfsense_lan_ip
  k8s_master_instance_type = var.k8s_master_instance_type
  k8s_worker_instance_type = var.k8s_worker_instance_type
  worker_count             = var.worker_count
  enable_wazuh             = var.enable_wazuh
  enable_rancher_vm        = var.enable_rancher_vm
  rancher_instance_type    = var.rancher_instance_type
  wazuh_instance_type      = var.wazuh_instance_type
}

# Định tuyến Private Route Table đẩy toàn bộ traffic ra Internet qua pfSense Firewall
resource "aws_route" "private_default_route_via_pfsense" {
  route_table_id         = module.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.compute.pfsense_lan_eni_id
}
