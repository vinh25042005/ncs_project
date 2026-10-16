variable "project_name" {
  description = "Tên dự án sử dụng để gắn nhãn (tag) tài nguyên"
  type        = string
  default     = "ncs-project"
}

variable "vpc_cidr" {
  description = "Dải địa chỉ IP CIDR block của VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_wan_cidr" {
  description = "Dải CIDR cho Public Subnet (WAN) dành cho pfSense Firewall"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_k8s_cidr" {
  description = "Dải CIDR cho Private Subnet (LAN) dành cho K3s Cluster"
  type        = string
  default     = "10.0.10.0/24"
}

variable "mgmt_cidr" {
  description = "Dải CIDR cho Management Subnet dành cho Wazuh SIEM Server"
  type        = string
  default     = "10.0.20.0/24"
}

variable "availability_zone" {
  description = "AWS Availability Zone triển khai tài nguyên"
  type        = string
  default     = "ap-southeast-1a"
}

variable "pfsense_lan_eni_id" {
  description = "ID của card mạng LAN pfSense dùng để cấu hình default route cho Private Route Table"
  type        = string
  default     = ""
}
