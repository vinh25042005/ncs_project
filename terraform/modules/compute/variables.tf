variable "project_name" {
  description = "Tên dự án sử dụng để gắn nhãn (tag) tài nguyên"
  type        = string
  default     = "ncs-project"
}

variable "vpc_id" {
  description = "ID của VPC ncs-project"
  type        = string
}

variable "key_name" {
  description = "Tên AWS EC2 Key Pair dùng để xác thực SSH"
  type        = string
}

variable "public_wan_subnet_id" {
  description = "ID của Public Subnet (WAN) dành cho Gateway 1 (AZ-a)"
  type        = string
}

variable "public_wan_b_subnet_id" {
  description = "ID của Public Subnet (WAN) dành cho Gateway 2 (AZ-b)"
  type        = string
  default     = ""
}

variable "private_k8s_subnet_id" {
  description = "ID của Private Subnet (LAN AZ-a) dành cho Kubernetes (kubeadm) Cluster"
  type        = string
}

variable "private_k8s_subnet_b_id" {
  description = "ID của Private Subnet (LAN AZ-b) dành cho Kubernetes Worker Node thứ 2"
  type        = string
  default     = ""
}

variable "mgmt_subnet_id" {
  description = "ID của Management Subnet dành cho Wazuh SIEM"
  type        = string
  default     = ""
}

variable "pfsense_sg_id" {
  description = "ID của Security Group dành cho tường lửa Gateway"
  type        = string
}

variable "k8s_sg_id" {
  description = "ID của Security Group dành cho các node Kubernetes Upstream"
  type        = string
}

variable "wazuh_sg_id" {
  description = "ID của Security Group dành cho máy chủ Wazuh SIEM"
  type        = string
  default     = ""
}

variable "pfsense_ami_id" {
  description = "AMI ID của pfSense Marketplace (để trống sẽ dùng Ubuntu Gateway + Suricata)"
  type        = string
  default     = ""
}

variable "pfsense_instance_type" {
  description = "Loại máy chủ EC2 cho Gateway Firewall"
  type        = string
  default     = "t3.small"
}

variable "pfsense_lan_ip" {
  description = "Địa chỉ IP tĩnh của cổng LAN Gateway 1 trong Private Subnet AZ-a"
  type        = string
  default     = "10.0.10.254"
}

variable "pfsense_2_lan_ip" {
  description = "Địa chỉ IP tĩnh của cổng LAN Gateway 2 trong Private Subnet AZ-b"
  type        = string
  default     = "10.0.11.254"
}

variable "wazuh_instance_type" {
  description = "Loại máy chủ EC2 cho Dedicated Wazuh SIEM Server"
  type        = string
  default     = "t3.small"
}

variable "k8s_master_instance_type" {
  description = "Loại máy chủ EC2 cho Kubernetes Control Plane Node"
  type        = string
  default     = "c7i-flex.large"
}

variable "k8s_worker_instance_type" {
  description = "Loại máy chủ EC2 cho Kubernetes Worker Nodes"
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
