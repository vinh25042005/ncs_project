variable "project_name" {
  type    = string
  default = "ncs-project"
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "availability_zone" {
  type    = string
  default = "ap-southeast-1a"
}

variable "key_name" {
  type        = string
  default     = "ncs-key"
  description = "Tên AWS EC2 Key Pair dùng để SSH vào các máy chủ"
}

variable "admin_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Địa chỉ IP/CIDR của bạn được phép truy cập SSH, pfSense GUI và Wazuh Dashboard"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_wan_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_k8s_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "mgmt_cidr" {
  type    = string
  default = "10.0.20.0/24"
}

variable "pfsense_ami_id" {
  type        = string
  default     = ""
  description = "AMI ID của pfSense Community Edition / Plus trên AWS Marketplace (nếu để trống sẽ dùng Ubuntu Security Gateway + Suricata)"
}

variable "pfsense_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "pfsense_lan_ip" {
  type    = string
  default = "10.0.10.254"
}

variable "k3s_master_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "k3s_worker_instance_type" {
  type    = string
  default = "t3.small"
}

variable "worker_count" {
  type    = number
  default = 1
}

variable "wazuh_instance_type" {
  type    = string
  default = "t3.medium"
}
