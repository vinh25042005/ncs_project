# Module: Network
# Tạo VPC 3 tầng: Public (WAN pfSense), Private (K3s Nodes), Management (Wazuh SIEM)

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 1. Public Subnet (WAN pfSense)
resource "aws_subnet" "public_wan" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_wan_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-wan"
    Role = "firewall-wan"
  }
}

# 2. Private Subnet (K3s Cluster - Master & Workers)
resource "aws_subnet" "private_k8s" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_k8s_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-subnet-private-k8s"
    Role = "k8s-nodes"
  }
}

# 3. Management Subnet (Wazuh SIEM)
resource "aws_subnet" "mgmt" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.mgmt_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-mgmt-wazuh"
    Role = "siem-monitoring"
  }
}

# Route table Public (WAN & Wazuh -> IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

resource "aws_route_table_association" "public_wan" {
  subnet_id      = aws_subnet.public_wan.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.public.id
}

# Route table Private (Toàn bộ traffic ra ngoài qua pfSense LAN interface)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # Nếu pfSense LAN ENI được cấu hình làm default gateway
  dynamic "route" {
    for_each = var.pfsense_lan_eni_id != "" ? [var.pfsense_lan_eni_id] : []
    content {
      cidr_block           = "0.0.0.0/0"
      network_interface_id = route.value
    }
  }

  tags = {
    Name = "${var.project_name}-rt-private"
  }
}

resource "aws_route_table_association" "private_k8s" {
  subnet_id      = aws_subnet.private_k8s.id
  route_table_id = aws_route_table.private.id
}
