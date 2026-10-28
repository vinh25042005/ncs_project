# Module: Security Groups

# 1. Security Group: pfSense Firewall
resource "aws_security_group" "pfsense" {
  name        = "${var.project_name}-sg-pfsense"
  description = "Security Group for pfSense Edge Firewall & Suricata IDS/IPS"
  vpc_id      = var.vpc_id

  # HTTP / HTTPS từ Internet vào cổng ngoài pfSense
  ingress {
    description = "HTTP to Ingress/App"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS to Ingress/App"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # OpenVPN
  ingress {
    description = "OpenVPN Tunnel"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH & WebConfigurator pfSense (Chỉ mở cho admin IP)
  ingress {
    description = "pfSense SSH Management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "pfSense WebGUI / Wazuh SIEM"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Rancher Management Server WebGUI"
    from_port   = 7443
    to_port     = 7443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Cho phép toàn bộ traffic từ mạng nội bộ VPC đi qua pfSense
  ingress {
    description = "VPC Internal Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-pfsense"
  }
}

// Security Group: Upstream Kubernetes Nodes (Private)
resource "aws_security_group" "k8s" {
  name        = "${var.project_name}-sg-k8s"
  description = "Security Group for Upstream Kubernetes Master and Worker Nodes"
  vpc_id      = var.vpc_id

  # Cho phép nội bộ các node K8s giao tiếp với nhau (Flannel, Kubelet, etcd)
  ingress {
    description = "Inter-node cluster communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Cho phép traffic từ pfSense forward tới K8s Ingress Controller (Port 80, 443, 6443, 9443 và NodePorts)
  ingress {
    description     = "HTTP Ingress from pfSense"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.pfsense.id]
  }

  ingress {
    description     = "HTTPS Ingress from pfSense"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.pfsense.id]
  }

  ingress {
    description     = "K8s API from pfSense"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.pfsense.id]
  }

  ingress {
    description     = "Wazuh API/Dashboard from pfSense"
    from_port       = 9443
    to_port         = 9443
    protocol        = "tcp"
    security_groups = [aws_security_group.pfsense.id]
  }

  ingress {
    description     = "K8s NodePort services from pfSense"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.pfsense.id]
  }

  # Cho phép SSH nội bộ từ VPC (qua VPN hoặc bastion)
  ingress {
    description = "Internal SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound via pfSense"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-k8s"
  }
}

# 3. Security Group: Wazuh SIEM Server
resource "aws_security_group" "wazuh" {
  name        = "${var.project_name}-sg-wazuh"
  description = "Security Group for Wazuh SIEM Manager & Dashboard"
  vpc_id      = var.vpc_id

  # Wazuh Agent enrollment & log collection từ VPC
  ingress {
    description = "Wazuh Agent Connection"
    from_port   = 1514
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Wazuh Dashboard & API (HTTPS) - Mở cho Admin IP và mạng nội bộ VPC (qua Gateway Port Forward)
  ingress {
    description     = "Wazuh Web Dashboard"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = [var.admin_cidr, var.vpc_cidr]
    security_groups = [aws_security_group.pfsense.id]
  }

  ingress {
    description     = "Wazuh API"
    from_port       = 55000
    to_port         = 55000
    protocol        = "tcp"
    cidr_blocks     = [var.admin_cidr, var.vpc_cidr]
    security_groups = [aws_security_group.pfsense.id]
  }

  # SSH - Mở cho Admin IP và Bastion qua VPC
  ingress {
    description = "SSH to Wazuh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr, var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-wazuh"
  }
}

# 4. Security Group: Rancher Management Server
resource "aws_security_group" "rancher" {
  name        = "${var.project_name}-sg-rancher"
  description = "Security Group for Rancher K8s Management Server & Web UI"
  vpc_id      = var.vpc_id

  # HTTP (chuyển hướng sang HTTPS)
  ingress {
    description = "HTTP Web Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # HTTPS (Rancher Web Dashboard)
  ingress {
    description = "HTTPS Rancher Dashboard"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # SSH
  ingress {
    description = "SSH to Rancher"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Giao tiếp nội bộ VPC cho K8s Cluster Agent kết nối về Rancher Server
  ingress {
    description = "Internal VPC communication from K8s to Rancher"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rancher"
  }
}
