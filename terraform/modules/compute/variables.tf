variable "project_name" {
  description = "Tên dự án sử dụng để gắn nhãn (tag) tài nguyên"
  type        = string
  default     = "ncs-project"
}

variable "key_name" {
  description = "Tên AWS EC2 Key Pair dùng để xác thực SSH"
  type        = string
}

variable "public_wan_subnet_id" {
  description = "ID của Public Subnet (WAN) dành cho pfSense"
  type        = string
}

variable "private_k8s_subnet_id" {
  description = "ID của Private Subnet (LAN AZ-a) dành cho K3s Cluster"
  type        = string
}

variable "private_k8s_subnet_b_id" {
  description = "ID của Private Subnet (LAN AZ-b) dành cho K3s Worker Node thứ 2"
  type        = string
  default     = ""
}

variable "mgmt_subnet_id" {
  description = "ID của Management Subnet dành cho Wazuh SIEM"
  type        = string
}

variable "pfsense_sg_id" {
  description = "ID của Security Group dành cho tường lửa pfSense"
  type        = string
}

variable "k8s_sg_id" {
  description = "ID của Security Group dành cho các node Kubernetes Upstream"
  type        = string
}



variable "pfsense_ami_id" {
  description = "AMI ID của pfSense Marketplace (để trống sẽ dùng Ubuntu Gateway + Suricata)"
  type        = string
  default     = ""
}

variable "pfsense_instance_type" {
  description = "Loại máy chủ EC2 cho pfSense Firewall"
  type        = string
  default     = "t3.small"
}

variable "pfsense_lan_ip" {
  description = "Địa chỉ IP tĩnh của cổng LAN pfSense trong Private Subnet"
  type        = string
  default     = "10.0.10.254"
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
}


