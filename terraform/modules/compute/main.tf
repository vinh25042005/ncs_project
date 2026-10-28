data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ─────────────────────────────────────────────────────────────
# 1. Edge Gateways (Gateway 1 in AZ-a & Gateway 2 in AZ-b)
# ─────────────────────────────────────────────────────────────

# ── Gateway 1 (AZ-a) ──

# WAN Interface (Public Subnet AZ-a)
resource "aws_network_interface" "pfsense_wan" {
  subnet_id         = var.public_wan_subnet_id
  security_groups   = [var.pfsense_sg_id]
  source_dest_check = false

  tags = {
    Name = "${var.project_name}-pfsense-1-wan-eni"
  }
}

# Elastic IP gắn vào WAN Gateway 1
resource "aws_eip" "pfsense" {
  domain            = "vpc"
  network_interface = aws_network_interface.pfsense_wan.id

  tags = {
    Name = "${var.project_name}-pfsense-1-eip"
  }
}

# LAN Interface (Private Subnet AZ-a)
resource "aws_network_interface" "pfsense_lan" {
  subnet_id         = var.private_k8s_subnet_id
  private_ips       = [var.pfsense_lan_ip]
  security_groups   = [var.pfsense_sg_id]
  source_dest_check = false

  tags = {
    Name = "${var.project_name}-pfsense-1-lan-eni"
  }
}

# EC2 Gateway 1 (Ubuntu + Suricata IDS + Ansible Bastion Controller)
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

  user_data = var.pfsense_ami_id != "" ? null : <<-EOF
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

              # Cấu hình Netplan lưu vĩnh viễn cấu hình 2 ENI với route chuẩn cho toàn VPC (10.0.0.0/16 qua 10.0.10.1)
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
                      - to: 10.0.0.0/16
                        via: 10.0.10.1
                        metric: 200
              NETPLAN
              chmod 600 /etc/netplan/60-dual-eni.yaml
              netplan apply || true

              # 1. NAT Masquerade ra ngoài Internet cho mạng Private K8s & Wazuh
              iptables -t nat -A POSTROUTING -o "$WAN_DEV" -j MASQUERADE
              iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
              iptables -A FORWARD -i "$LAN_DEV" -o "$WAN_DEV" -j ACCEPT

              # 2. Port Forwarding HTTP (80), HTTPS (443), Rancher (7443) & Wazuh API (8443 -> 55000)
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 80 -j DNAT --to-destination 10.0.10.10:80
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 443 -j DNAT --to-destination 10.0.10.10:443
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 7443 -j DNAT --to-destination 10.0.10.10:30443
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 8443 -j DNAT --to-destination 10.0.20.10:55000
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 80 -j ACCEPT
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 443 -j ACCEPT
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 30443 -j ACCEPT
              iptables -A FORWARD -p tcp -d 10.0.20.10 --dport 55000 -j ACCEPT

              # 3. LAN Masquerade: Đảm bảo traffic phản hồi quay về đúng Gateway (Chống Asymmetric Routing)
              iptables -t nat -A POSTROUTING -o "$LAN_DEV" -j MASQUERADE

              # Cài đặt Suricata IDS & Ansible Controller & lưu cấu hình iptables
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y iptables-persistent suricata ansible
              netfilter-persistent save
              systemctl enable suricata
              EOF

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-gateway-1"
    Role = "edge-firewall"
  }
}

# ── Gateway 2 (AZ-b) ──

# WAN Interface (Public Subnet AZ-b)
resource "aws_network_interface" "pfsense_2_wan" {
  subnet_id         = var.public_wan_b_subnet_id
  security_groups   = [var.pfsense_sg_id]
  source_dest_check = false

  tags = {
    Name = "${var.project_name}-pfsense-2-wan-eni"
  }
}

# Elastic IP gắn vào WAN Gateway 2
resource "aws_eip" "pfsense_2" {
  domain            = "vpc"
  network_interface = aws_network_interface.pfsense_2_wan.id

  tags = {
    Name = "${var.project_name}-pfsense-2-eip"
  }
}

# LAN Interface (Private Subnet AZ-b)
resource "aws_network_interface" "pfsense_2_lan" {
  subnet_id         = var.private_k8s_subnet_b_id
  private_ips       = [var.pfsense_2_lan_ip]
  security_groups   = [var.pfsense_sg_id]
  source_dest_check = false

  tags = {
    Name = "${var.project_name}-pfsense-2-lan-eni"
  }
}

# EC2 Gateway 2 (Ubuntu + Suricata IDS)
resource "aws_instance" "pfsense_2" {
  ami           = var.pfsense_ami_id != "" ? var.pfsense_ami_id : data.aws_ami.ubuntu.id
  instance_type = var.pfsense_instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.pfsense_2_wan.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.pfsense_2_lan.id
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

  user_data = var.pfsense_ami_id != "" ? null : <<-EOF
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
              ip addr add ${var.pfsense_2_lan_ip}/24 dev "$LAN_DEV" 2>/dev/null || true
              ip route del default dev "$LAN_DEV" 2>/dev/null || true

              # Cấu hình Netplan lưu vĩnh viễn cấu hình 2 ENI với route chuẩn cho toàn VPC (10.0.0.0/16 qua 10.0.11.1)
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
                      - ${var.pfsense_2_lan_ip}/24
                    routes:
                      - to: 10.0.0.0/16
                        via: 10.0.11.1
                        metric: 200
              NETPLAN
              chmod 600 /etc/netplan/60-dual-eni.yaml
              netplan apply || true

              # 1. NAT Masquerade ra ngoài Internet cho mạng Private K8s AZ-b
              iptables -t nat -A POSTROUTING -o "$WAN_DEV" -j MASQUERADE
              iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
              iptables -A FORWARD -i "$LAN_DEV" -o "$WAN_DEV" -j ACCEPT

              # 2. Port Forwarding HTTP (80), HTTPS (443), Rancher (7443) & Wazuh API (8443 -> 55000)
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 80 -j DNAT --to-destination 10.0.10.10:80
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 443 -j DNAT --to-destination 10.0.10.10:443
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 7443 -j DNAT --to-destination 10.0.10.10:30443
              iptables -t nat -A PREROUTING -i "$WAN_DEV" -p tcp --dport 8443 -j DNAT --to-destination 10.0.20.10:55000
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 80 -j ACCEPT
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 443 -j ACCEPT
              iptables -A FORWARD -p tcp -d 10.0.10.10 --dport 30443 -j ACCEPT
              iptables -A FORWARD -p tcp -d 10.0.20.10 --dport 55000 -j ACCEPT

              # 3. LAN Masquerade: Đảm bảo traffic phản hồi quay về đúng Gateway (Chống Asymmetric Routing)
              iptables -t nat -A POSTROUTING -o "$LAN_DEV" -j MASQUERADE

              # Cài đặt Suricata IDS & lưu cấu hình iptables
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y iptables-persistent suricata
              netfilter-persistent save
              systemctl enable suricata
              EOF

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-gateway-2"
    Role = "edge-firewall"
  }
}

# ─────────────────────────────────────────────────────────────
# 2. AWS Network Load Balancer (NLB - Multi-AZ Active-Active)
# ─────────────────────────────────────────────────────────────

locals {
  nlb_ports = {
    "80"   = 80
    "443"  = 443
    "7443" = 7443
    "8443" = 8443
  }
}

resource "aws_lb" "nlb" {
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [var.public_wan_subnet_id, var.public_wan_b_subnet_id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-nlb"
    Role = "edge-load-balancer"
  }
}

resource "aws_lb_target_group" "tcp" {
  for_each    = local.nlb_ports
  name        = "${var.project_name}-tg-${each.key}"
  port        = each.value
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = each.value
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg-${each.key}"
  }
}

resource "aws_lb_target_group_attachment" "gw1" {
  for_each         = local.nlb_ports
  target_group_arn = aws_lb_target_group.tcp[each.key].arn
  target_id        = aws_network_interface.pfsense_wan.private_ip
  port             = each.value
}

resource "aws_lb_target_group_attachment" "gw2" {
  for_each         = local.nlb_ports
  target_group_arn = aws_lb_target_group.tcp[each.key].arn
  target_id        = aws_network_interface.pfsense_2_wan.private_ip
  port             = each.value
}

resource "aws_lb_listener" "tcp" {
  for_each          = local.nlb_ports
  load_balancer_arn = aws_lb.nlb.arn
  port              = each.value
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp[each.key].arn
  }
}

# ─────────────────────────────────────────────────────────────
# 3. Dedicated Wazuh SIEM Server (Management Subnet)
# ─────────────────────────────────────────────────────────────

resource "aws_instance" "wazuh" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.wazuh_instance_type
  key_name               = var.key_name
  subnet_id              = var.mgmt_subnet_id
  vpc_security_group_ids = [var.wazuh_sg_id]
  private_ip             = "10.0.20.10"

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

              # Đợi Gateway 1 sẵn sàng trước khi kết nối Internet
              until ping -c 1 -W 2 ${var.pfsense_lan_ip} >/dev/null 2>&1; do
                echo "Đang đợi Gateway ${var.pfsense_lan_ip}..."
                sleep 3
              done
              EOF

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-wazuh-siem"
    Role = "siem-server"
  }
}

# ─────────────────────────────────────────────────────────────
# 4. Upstream Kubernetes Cluster (Master & Multi-AZ Worker Nodes)
# ─────────────────────────────────────────────────────────────

// K8s Master node
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
    http_tokens                 = "required" // IMDSv2 Enforced
    http_put_response_hop_limit = 2
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

              # Tắt hoàn toàn Swap theo khuyến nghị của Upstream Kubernetes (kubeadm)
              swapoff -a || true
              sed -i '/swap/d' /etc/fstab
              rm -f /swapfile
              EOF

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-k8s-master"
    Role = "k8s-control-plane"
  }
}

// K8s Worker nodes (Multi-AZ)
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
    http_tokens                 = "required" // IMDSv2 Enforced
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # OS Hardening cơ bản
              echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.d/99-security.conf
              echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.d/99-security.conf
              sysctl --system

              GATEWAY_IP="${count.index % 2 == 0 ? var.pfsense_lan_ip : var.pfsense_2_lan_ip}"
              # Đợi Gateway sẵn sàng trước khi kết nối Internet
              until ping -c 1 -W 2 "$GATEWAY_IP" >/dev/null 2>&1; do
                echo "Đang đợi Gateway $GATEWAY_IP..."
                sleep 3
              done

              # Tắt hoàn toàn Swap theo khuyến nghị của Upstream Kubernetes (kubeadm)
              swapoff -a || true
              sed -i '/swap/d' /etc/fstab
              rm -f /swapfile
              EOF

  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "${var.project_name}-k8s-worker-${count.index + 1}"
    Role = "k8s-worker"
  }
}
