terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Cấu hình lưu trữ State tập trung trên S3 + State Locking (chống 2 người apply cùng lúc)
  backend "s3" {
    bucket         = "ncs-project-tfstate" # Thay bằng tên S3 bucket sinh ra từ terraform/bootstrap/
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "ncs-project-tflocks" # Bảng DynamoDB quản lý LockID
    use_lockfile   = true                  # S3 native locking (Terraform >= 1.10)
  }
}


provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# 1. Module Mạng (VPC, Subnet WAN, Subnet Private K8s, Subnet Mgmt Wazuh)
module "network" {
  source            = "./modules/network"
  project_name      = var.project_name
  vpc_cidr          = var.vpc_cidr
  public_wan_cidr   = var.public_wan_cidr
  private_k8s_cidr  = var.private_k8s_cidr
  mgmt_cidr         = var.mgmt_cidr
  availability_zone = var.availability_zone
}

# 2. Module Security Groups (pfSense SG, K3s Private SG, Wazuh SG)
module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  vpc_cidr     = var.vpc_cidr
  admin_cidr   = var.admin_cidr
}

# 3. Module Compute (pfSense Gateway, K3s Master & Worker, Wazuh SIEM)
module "compute" {
  source                   = "./modules/compute"
  project_name             = var.project_name
  key_name                 = var.key_name
  public_wan_subnet_id     = module.network.public_wan_subnet_id
  private_k8s_subnet_id    = module.network.private_k8s_subnet_id
  mgmt_subnet_id           = module.network.mgmt_subnet_id
  pfsense_sg_id            = module.security.pfsense_sg_id
  k3s_sg_id                = module.security.k3s_sg_id
  wazuh_sg_id              = module.security.wazuh_sg_id
  pfsense_ami_id           = var.pfsense_ami_id
  pfsense_instance_type    = var.pfsense_instance_type
  pfsense_lan_ip           = var.pfsense_lan_ip
  k3s_master_instance_type = var.k3s_master_instance_type
  k3s_worker_instance_type = var.k3s_worker_instance_type
  worker_count             = var.worker_count
  wazuh_instance_type      = var.wazuh_instance_type
  k3s_cluster_token        = var.k3s_cluster_token
}

# Định tuyến Private Route Table đẩy toàn bộ traffic ra Internet qua pfSense Firewall
resource "aws_route" "private_default_route_via_pfsense" {
  route_table_id         = module.network.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.compute.pfsense_lan_eni_id
}
