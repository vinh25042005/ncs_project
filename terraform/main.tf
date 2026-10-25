// 1. Mạng Multi-AZ
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

// 2. Tường lửa Security Groups
module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  vpc_cidr     = var.vpc_cidr
  admin_cidr   = var.admin_cidr
}

// 3. Máy chủ EC2 (Gateway & K8s Cluster)
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
  pfsense_ami_id           = var.pfsense_ami_id
  pfsense_instance_type    = var.pfsense_instance_type
  pfsense_lan_ip           = var.pfsense_lan_ip
  k8s_master_instance_type = var.k8s_master_instance_type
  k8s_worker_instance_type = var.k8s_worker_instance_type
  worker_count             = var.worker_count
}

// 4. Định tuyến Internet qua Gateway
resource "aws_route" "private_default_route_via_pfsense" {
  route_table_id         = module.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.compute.pfsense_lan_eni_id
}
