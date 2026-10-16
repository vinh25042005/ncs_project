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
  description = "ID của Private Subnet (LAN) dành cho K3s Cluster"
  type        = string
}

variable "mgmt_subnet_id" {
  description = "ID của Management Subnet dành cho Wazuh SIEM"
  type        = string
}

variable "pfsense_sg_id" {
  description = "ID của Security Group dành cho tường lửa pfSense"
  type        = string
}

variable "k3s_sg_id" {
  description = "ID của Security Group dành cho các node K3s"
  type        = string
}

variable "wazuh_sg_id" {
  description = "ID của Security Group dành cho Wazuh SIEM"
  type        = string
}

variable "rancher_sg_id" {
  description = "ID của Security Group dành cho Rancher Management Server"
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
  default     = "t2.small"
}

variable "pfsense_lan_ip" {
  description = "Địa chỉ IP tĩnh của cổng LAN pfSense trong Private Subnet"
  type        = string
  default     = "10.0.10.254"
}

variable "k3s_master_instance_type" {
  description = "Loại máy chủ EC2 cho K3s Control Plane Node"
  type        = string
  default     = "c7i-flex.large"
}

variable "k3s_worker_instance_type" {
  description = "Loại máy chủ EC2 cho K3s Worker Nodes"
  type        = string
  default     = "t2.small"
}

variable "worker_count" {
  description = "Số lượng K3s Worker Nodes"
  type        = number
  default     = 2
}

variable "rancher_instance_type" {
  description = "Loại máy chủ EC2 cho Rancher Management Server"
  type        = string
  default     = "c7i-flex.large"
}

variable "wazuh_instance_type" {
  description = "Loại máy chủ EC2 cho Wazuh SIEM Server"
  type        = string
  default     = "t2.small"
}

variable "k3s_cluster_token" {
  description = "Token bí mật dùng để xác thực và kết nối Worker vào K3s Master"
  type        = string
  default     = "ncs-secret-cluster-token-2026"
  sensitive   = true
}
