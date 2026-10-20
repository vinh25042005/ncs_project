# ==============================================================================
# Module: Compute
# Provisioning: pfSense Gateway (Dual ENI), Upstream K8s Master & Workers, Wazuh
# Security Hardening: IMDSv2 Enforced, KMS EBS Encryption, Multi-AZ Subnets
# ==============================================================================

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

# LAN Interface (Private Subnet - Gateway cho cụm K8s)
resource "aws_network_interface" "pfsense_lan" {
  subnet_id         = var.private_k8s_subnet_id
  private_ips       = [var.pfsense_lan_ip]
  security_groups   = [var.pfsense_sg_id]
  source_dest_check = false

  tags = {
    Name = "${var.project_name}-pfsense-lan-eni"
  }
}

# EC2 Security Gateway (Ubuntu Security Gateway + Suricata IDS)
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

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 Enforced
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Kích hoạt chuyển tiếp gói tin (IP Forwarding)
              cat << 'SYSCTL' > /etc/sysctl.d/99-router.conf
              net.ipv4.ip_forward = 1
              net.ipv4.conf.all.forwarding = 1
              net.ipv4.conf.all.send_redirects = 0
              net.ipv4.conf.default.send_redirects = 0
              net.ipv4.conf.all.accept_redirects = 0
              net.ipv4.conf.default.accept_redirects = 0
              SYSCTL
              sysctl --system

              # Nhận diện card mạng WAN và LAN
              WAN_DEV=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
              [ -z "$WAN_DEV" ] && WAN_DEV="ens5"
              LAN_DEV=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | grep -v "$WAN_DEV" | head -n1)
              [ -z "$LAN_DEV" ] && LAN_DEV="ens6"

              # Bật card mạng LAN và gán IP LAN cố định
              ip link set "$LAN_DEV" up || true
              ip addr add ${var.pfsense_lan_ip}/24 dev "$LAN_DEV" 2>/dev/null || true
              ip route del default dev "$LAN_DEV" 2>/dev/null || true

              # Cấu hình Netplan lưu vĩnh viễn cấu hình 2 ENI
              cat << NETPLAN > /etc/netplan/60-dual-eni.yaml
              network:
                version: 2
                renderer: networkd
                ethernets:
                  $WAN_DEV:
                    dhcp4: true
                    dhcp4-overrides:
                      route-metric: 100
                  $LAN_DEV:
                    dhcp4: false
                    addresses:
                      - ${var.pfsense_lan_ip}/24
                    routes:
                      - to: 10.0.10.0/24
                        via: ${var.pfsense_lan_ip}
                        metric: 200
              NETPLAN
              chmod 600 /etc/netplan/60-dual-eni.yaml

              # 1. NAT Masquerade ra ngoài Internet cho mạng Private K8s
              iptables -t nat -A POSTROUTING -o "$WAN_DEV" -j MASQUERADE
              iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
              iptables -A FORWARD -i "$LAN_DEV" -o "$WAN_DEV" -j ACCEPT

              # 2. Port Forwarding HTTP (80) & HTTPS (443) tới K8s Ingress (10.0.10.10)
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 80 -j DNAT --to-destination 10.0.10.10:80
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 443 -j DNAT --to-destination 10.0.10.10:443
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 80 -j ACCEPT
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 443 -j ACCEPT

              # 3. Masquerade trên LAN để đảm bảo traffic phản hồi quay về đúng Gateway
              iptables -t nat -A POSTROUTING -o "$LAN_DEV" -d 10.0.10.10 -p tcp --dport 80 -j MASQUERADE
              iptables -t nat -A POSTROUTING -o "$LAN_DEV" -d 10.0.10.10 -p tcp --dport 443 -j MASQUERADE

              # Cài đặt Suricata IDS & Ansible Controller & lưu cấu hình iptables
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y iptables-persistent suricata ansible
              netfilter-persistent save
              systemctl enable suricata
              EOF

  tags = {
    Name = "${var.project_name}-firewall-suricata"
    Role = "edge-firewall"
  }
}

# ─────────────────────────────────────────────────────────────
# 2. Upstream Kubernetes Cluster (Master & Multi-AZ Worker Nodes)
# ─────────────────────────────────────────────────────────────

moved {
  from = aws_instance.k3s_master
  to   = aws_instance.k8s_master
}

moved {
  from = aws_instance.k3s_worker
  to   = aws_instance.k8s_worker
}

# Kubernetes Master Node (Control Plane + Ingress + HPA)
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.k8s_master_instance_type
  key_name               = var.key_name
  subnet_id              = var.private_k8s_subnet_id
  vpc_security_group_ids = [var.k8s_sg_id]
  private_ip             = "10.0.10.10"

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 Enforced
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # OS Hardening cơ bản
              echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.d/99-security.conf
              echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.d/99-security.conf
              sysctl --system

              # Đợi pfSense Gateway sẵn sàng trước khi kết nối Internet
              until ping -c 1 -W 2 ${var.pfsense_lan_ip} >/dev/null 2>&1; do
                echo "Đang đợi Gateway ${var.pfsense_lan_ip}..."
                sleep 3
              done

              # Tạo 4GB swap file để làm đệm an toàn cho cụm K8s & Rancher
              if [ ! -f /swapfile ]; then
                fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
              fi
              EOF

  tags = {
    Name = "${var.project_name}-k8s-master"
    Role = "k8s-control-plane"
  }
}

# Kubernetes Worker Node (Phân bổ qua 2 AZ: AZ-a & AZ-b)
resource "aws_instance" "k8s_worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.k8s_worker_instance_type
  key_name               = var.key_name
  subnet_id              = count.index % 2 == 0 ? var.private_k8s_subnet_id : (var.private_k8s_subnet_b_id != "" ? var.private_k8s_subnet_b_id : var.private_k8s_subnet_id)
  vpc_security_group_ids = [var.k8s_sg_id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 Enforced
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # OS Hardening cơ bản
              echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.d/99-security.conf
              echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.d/99-security.conf
              sysctl --system

              # Đợi pfSense Gateway sẵn sàng trước khi kết nối Internet
              until ping -c 1 -W 2 ${var.pfsense_lan_ip} >/dev/null 2>&1; do
                echo "Đang đợi Gateway ${var.pfsense_lan_ip}..."
                sleep 3
              done

              # Tạo 2GB swap file để làm đệm an toàn cho node worker
              if [ ! -f /swapfile ]; then
                fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
              fi
              EOF

  tags = {
    Name = "${var.project_name}-k8s-worker-${count.index + 1}"
    Role = "k8s-worker"
  }
}

# ─────────────────────────────────────────────────────────────
# 3. Wazuh SIEM Server (Tùy chọn)
# ─────────────────────────────────────────────────────────────

resource "aws_instance" "wazuh" {
  count                       = var.enable_wazuh ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.wazuh_instance_type
  key_name                    = var.key_name
  subnet_id                   = var.mgmt_subnet_id
  vpc_security_group_ids      = [var.wazuh_sg_id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = "${var.project_name}-wazuh-siem"
    Role = "siem-dashboard"
  }
}

# ─────────────────────────────────────────────────────────────
# 4. Rancher Management Server (Tùy chọn nếu có thêm vCPU)
# ─────────────────────────────────────────────────────────────

resource "aws_instance" "rancher" {
  count                       = var.enable_rancher_vm ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.rancher_instance_type
  key_name                    = var.key_name
  subnet_id                   = var.mgmt_subnet_id
  vpc_security_group_ids      = [var.rancher_sg_id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Cài đặt Docker CE
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io

              # Khởi chạy Rancher Server container
              systemctl enable --now docker
              docker run -d --restart=unless-stopped \
                -p 80:80 -p 443:443 \
                --privileged \
                --name rancher-server \
                rancher/rancher:stable
              EOF

  tags = {
    Name = "${var.project_name}-rancher-server"
    Role = "k8s-management-dashboard"
  }
}
