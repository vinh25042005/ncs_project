variable "project_name" {
  description = "Tên dự án sử dụng để gắn nhãn (tag) tài nguyên"
  type        = string
  default     = "ncs-project"
}

variable "region" {
  description = "AWS Region triển khai hạ tầng"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "Tên AWS CLI Profile được cấu hình trên máy"
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
  description = "Địa chỉ IP/CIDR của bạn được phép truy cập SSH, pfSense GUI và Wazuh Dashboard"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "Giá trị admin_cidr phải là một định dạng CIDR IPv4 hợp lệ."
  }
}

variable "vpc_cidr" {
  description = "Dải CIDR block cho VPC ncs-project"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Giá trị vpc_cidr phải là một định dạng CIDR IPv4 hợp lệ."
  }
}

variable "public_wan_cidr" {
  description = "Dải CIDR cho Public Subnet (WAN) dành cho pfSense Firewall"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_k8s_cidr" {
  description = "Dải CIDR cho Private Subnet (LAN) dành cho K8s Cluster"
  type        = string
  default     = "10.0.10.0/24"
}

variable "mgmt_cidr" {
  description = "Dải CIDR cho Management Subnet dành cho Wazuh SIEM Server"
  type        = string
  default     = "10.0.20.0/24"
}

variable "pfsense_ami_id" {
  description = "AMI ID của pfSense Community Edition / Plus trên AWS Marketplace (nếu để trống sẽ dùng Ubuntu Security Gateway + Suricata)"
  type        = string
  default     = ""
}

variable "pfsense_instance_type" {
  description = "Loại máy chủ EC2 cho pfSense Firewall"
  type        = string
  default     = "t3.small"
}

variable "pfsense_lan_ip" {
  description = "Địa chỉ IP cổng LAN của pfSense trong mạng nội bộ K8s"
  type        = string
  default     = "10.0.10.254"
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
}

variable "enable_wazuh" {
  description = "Bật/Tắt máy chủ Wazuh SIEM EC2 riêng biệt (mặc định tắt để nhường vCPU cho 2 Worker)"
  type        = bool
  default     = false
}

variable "enable_rancher_vm" {
  description = "Bật/Tắt máy chủ Rancher EC2 riêng biệt (mặc định tắt, Rancher chạy trực tiếp trên K8s)"
  type        = bool
  default     = false
}

variable "rancher_instance_type" {
  description = "Loại máy chủ EC2 cho Rancher Management Server nếu bật VM riêng"
  type        = string
  default     = "c7i-flex.large"
}

variable "wazuh_instance_type" {
  description = "Loại máy chủ EC2 cho Wazuh SIEM Server nếu bật"
  type        = string
  default     = "t3.small"
}
