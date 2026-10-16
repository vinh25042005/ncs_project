variable "project_name" {
  type    = string
  default = "ncs-project"
}

variable "key_name" {
  type        = string
  description = "AWS EC2 Key Pair Name"
}

variable "public_wan_subnet_id" {
  type = string
}

variable "private_k8s_subnet_id" {
  type = string
}

variable "mgmt_subnet_id" {
  type = string
}

variable "pfsense_sg_id" {
  type = string
}

variable "k3s_sg_id" {
  type = string
}

variable "wazuh_sg_id" {
  type = string
}

variable "pfsense_ami_id" {
  type        = string
  default     = ""
  description = "Optional AMI ID for pfSense. If empty, Ubuntu with Suricata gateway is provisioned."
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
