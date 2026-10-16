# Module: Compute
# Provisioning: pfSense Firewall (Dual ENI), K3s Server, K3s Worker, Wazuh SIEM

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ─────────────────────────────────────────────────────────────
# 1. pfSense / Security Gateway (Tường lửa biên & Suricata IDS)
# ─────────────────────────────────────────────────────────────

# WAN Interface (Public Subnet)
resource "aws_network_interface" "pfsense_wan" {
  subnet_id         = var.public_wan_subnet_id
  security_groups   = [var.pfsense_sg_id]
  source_dest_check = false

  tags = {
    Name = "${var.project_name}-pfsense-wan-eni"
  }
}

# Elastic IP gắn vào WAN
resource "aws_eip" "pfsense" {
  domain            = "vpc"
  network_interface = aws_network_interface.pfsense_wan.id

  tags = {
    Name = "${var.project_name}-pfsense-eip"
  }
}

# LAN Interface (Private Subnet - Gateway cho cụm K3s)
resource "aws_network_interface" "pfsense_lan" {
  subnet_id         = var.private_k8s_subnet_id
  private_ips       = [var.pfsense_lan_ip]
  security_groups   = [var.pfsense_sg_id]
  source_dest_check = false

  tags = {
    Name = "${var.project_name}-pfsense-lan-eni"
  }
}

# EC2 Security Gateway (Cài đặt pfSense hoặc Ubuntu Security Gateway + Suricata)
resource "aws_instance" "pfsense" {
  ami           = var.pfsense_ami_id != "" ? var.pfsense_ami_id : data.aws_ami.ubuntu.id
  instance_type = var.pfsense_instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.pfsense_wan.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.pfsense_lan.id
    device_index         = 1
  }

  user_data = <<-EOF
              #!/bin/bash
              echo 1 > /proc/sys/net/ipv4/ip_forward
              sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
              apt-get update -y
              apt-get install -y suricata iptables-persistent
              systemctl enable suricata
              EOF

  tags = {
    Name = "${var.project_name}-firewall-suricata"
    Role = "edge-firewall"
  }
}

# ─────────────────────────────────────────────────────────────
# 2. K3s Cluster (Master & Worker Nodes - Nằm trong Private Subnet)
# ─────────────────────────────────────────────────────────────

# K3s Master Node (Control Plane + Ingress + HPA)
resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.k3s_master_instance_type
  key_name               = var.key_name
  subnet_id              = var.private_k8s_subnet_id
  vpc_security_group_ids = [var.k3s_sg_id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # OS Hardening cơ bản
              echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.d/99-security.conf
              echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.d/99-security.conf
              sysctl --system

              # Thư mục lưu audit logs
              mkdir -p /var/log/kubernetes /etc/rancher/k3s

              # Cấu hình K8s Audit Policy cho Wazuh thu thập
              cat << 'POLICY' > /etc/rancher/k3s/audit-policy.yaml
              apiVersion: audit.k8s.io/v1
              kind: Policy
              rules:
                - level: Metadata
                  resources:
                    - group: ""
                      resources: ["secrets", "configmaps"]
                - level: RequestResponse
                  resources:
                    - group: ""
                      resources: ["pods", "pods/exec"]
                - level: Metadata
              POLICY

              # Cài K3s với Audit Logging kích hoạt
              curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
                --disable traefik \
                --kube-apiserver-arg=audit-log-path=/var/log/kubernetes/audit.log \
                --kube-apiserver-arg=audit-policy-file=/etc/rancher/k3s/audit-policy.yaml \
                --kube-apiserver-arg=audit-log-maxsize=100 \
                --kube-apiserver-arg=audit-log-maxbackup=3" sh -

              # Lưu node token để worker join
              sleep 10
              chmod 644 /etc/rancher/k3s/k3s.yaml
              EOF

  tags = {
    Name = "${var.project_name}-k3s-master"
    Role = "k3s-control-plane"
  }
}

# K3s Worker Node
resource "aws_instance" "k3s_worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.k3s_worker_instance_type
  key_name               = var.key_name
  subnet_id              = var.private_k8s_subnet_id
  vpc_security_group_ids = [var.k3s_sg_id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-k3s-worker-${count.index + 1}"
    Role = "k3s-worker"
  }
}

# ─────────────────────────────────────────────────────────────
# 3. Wazuh SIEM Server (Quản lý log an ninh, SIEM Dashboard & SOAR)
# ─────────────────────────────────────────────────────────────

resource "aws_instance" "wazuh" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.wazuh_instance_type
  key_name                    = var.key_name
  subnet_id                   = var.mgmt_subnet_id
  vpc_security_group_ids      = [var.wazuh_sg_id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-wazuh-siem"
    Role = "siem-dashboard"
  }
}
