variable "project_name" {
  description = "Tên dự án"
  type        = string
  default     = "ncs-project"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "Tên AWS CLI Profile"
  type        = string
  default     = "default"
}

variable "availability_zone" {
  description = "AWS Availability Zone A"
  type        = string
  default     = "ap-southeast-1a"
}

variable "availability_zone_b" {
  description = "AWS Availability Zone B (cho Multi-AZ)"
  type        = string
  default     = "ap-southeast-1b"
}

variable "key_name" {
  description = "Tên AWS EC2 Key Pair dùng để SSH vào các máy chủ"
  type        = string
  default     = "ncs-key"
}

variable "admin_cidr" {
  description = "Địa chỉ IP/CIDR được phép truy cập SSH, Gateway GUI và Wazuh Dashboard (Khuyến nghị dùng IP admin cố định thay vì 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "CIDR IPv4 không hợp lệ."
  }
}

variable "vpc_cidr" {
  description = "Dải CIDR block cho VPC ncs-project"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "CIDR IPv4 không hợp lệ."
  }
}

variable "public_wan_cidr" {
  description = "Dải CIDR cho Public Subnet (WAN AZ-a) dành cho Gateway Firewall 1"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_wan_cidr, 0))
    error_message = "CIDR IPv4 không hợp lệ."
  }
}

variable "public_wan_b_cidr" {
  description = "Dải CIDR cho Public Subnet (WAN AZ-b) dành cho Gateway Firewall 2"
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.public_wan_b_cidr, 0))
    error_message = "CIDR IPv4 không hợp lệ."
  }
}

variable "private_k8s_cidr" {
  description = "Dải CIDR cho Private Subnet (LAN AZ-a) dành cho K8s Cluster"
  type        = string
  default     = "10.0.10.0/24"

  validation {
    condition     = can(cidrhost(var.private_k8s_cidr, 0))
    error_message = "CIDR IPv4 không hợp lệ."
  }
}

variable "private_k8s_b_cidr" {
  description = "Dải CIDR cho Private Subnet (LAN AZ-b) dành cho K8s Cluster"
  type        = string
  default     = "10.0.11.0/24"

  validation {
    condition     = can(cidrhost(var.private_k8s_b_cidr, 0))
    error_message = "CIDR IPv4 không hợp lệ."
  }
}

variable "mgmt_cidr" {
  description = "Dải CIDR cho Management Subnet dành cho Wazuh SIEM Server"
  type        = string
  default     = "10.0.20.0/24"

  validation {
    condition     = can(cidrhost(var.mgmt_cidr, 0))
    error_message = "CIDR IPv4 không hợp lệ."
  }
}

variable "pfsense_ami_id" {
  description = "AMI ID của pfSense Community Edition / Plus trên AWS Marketplace"
  type        = string
  default     = ""
}

variable "pfsense_instance_type" {
  description = "Loại máy chủ EC2 cho Gateway Firewall"
  type        = string
  default     = "t3.small"
}

variable "pfsense_lan_ip" {
  description = "Địa chỉ IP cổng LAN của Gateway 1 trong mạng nội bộ K8s AZ-a"
  type        = string
  default     = "10.0.10.254"
}

variable "pfsense_2_lan_ip" {
  description = "Địa chỉ IP cổng LAN của Gateway 2 trong mạng nội bộ K8s AZ-b"
  type        = string
  default     = "10.0.11.254"
}

variable "k8s_master_instance_type" {
  description = "Loại máy chủ EC2 cho Upstream Kubernetes Control Plane Node"
  type        = string
  default     = "c7i-flex.large"
}

variable "k8s_worker_instance_type" {
  description = "Loại máy chủ EC2 cho Upstream Kubernetes Worker Nodes"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Số lượng Kubernetes Worker Nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 1
    error_message = "Số lượng worker nodes phải lớn hơn hoặc bằng 1."
  }
}
