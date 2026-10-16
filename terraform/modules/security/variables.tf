variable "project_name" {
  type    = string
  default = "ncs-project"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "admin_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR block allowed to access management interfaces (SSH, pfSense GUI, Wazuh Dashboard)"
}
