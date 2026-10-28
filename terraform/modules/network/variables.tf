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
  description = "Dải CIDR cho Public Subnet (WAN AZ-a)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_wan_b_cidr" {
  description = "Dải CIDR cho Public Subnet (WAN AZ-b)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_k8s_cidr" {
  description = "Dải CIDR cho Private Subnet Kubernetes (AZ-a)"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_k8s_b_cidr" {
  description = "Dải CIDR cho Private Subnet Kubernetes (AZ-b)"
  type        = string
  default     = "10.0.11.0/24"
}

variable "mgmt_cidr" {
  description = "Dải CIDR cho Management Subnet (AZ-a)"
  type        = string
  default     = "10.0.20.0/24"
}

variable "availability_zone" {
  description = "AWS Availability Zone A"
  type        = string
  default     = "ap-southeast-1a"
}

variable "availability_zone_b" {
  description = "AWS Availability Zone B"
  type        = string
  default     = "ap-southeast-1b"
}
