variable "project_name" {
  description = "Tên dự án sử dụng để gắn nhãn (tag) tài nguyên"
  type        = string
  default     = "ncs-project"
}

variable "vpc_id" {
  description = "ID của VPC nơi áp dụng các Security Groups"
  type        = string
}

variable "vpc_cidr" {
  description = "Dải CIDR của VPC để cho phép lưu lượng mạng nội bộ"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_cidr" {
  description = "Dải IP quản trị viên được phép truy cập SSH (22), pfSense WebGUI (8443) và Wazuh Dashboard (443)"
  type        = string
  default     = "0.0.0.0/0"
}
