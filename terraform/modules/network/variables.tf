variable "project_name" {
  type    = string
  default = "ncs-project"
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

variable "availability_zone" {
  type    = string
  default = "ap-southeast-1a"
}

variable "pfsense_lan_eni_id" {
  type        = string
  default     = ""
  description = "ENI ID of pfSense LAN interface to route private traffic through"
}
