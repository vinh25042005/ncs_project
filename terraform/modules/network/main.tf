# Module: Network

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

# 1. Public Subnet (WAN pfSense) - AZ-a & AZ-b
resource "aws_subnet" "public_wan" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_wan_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-wan-a"
    Role = "firewall-wan"
  }
}

resource "aws_subnet" "public_wan_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_wan_b_cidr
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-wan-b"
    Role = "firewall-wan"
  }
}

# 2. Private Subnets 
resource "aws_subnet" "private_k8s" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_k8s_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-subnet-private-k8s-a"
    Role = "k8s-nodes"
  }
}

resource "aws_subnet" "private_k8s_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_k8s_b_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = "${var.project_name}-subnet-private-k8s-b"
    Role = "k8s-nodes"
  }
}

# 3. Management Subnet (Wazuh SIEM / Rancher)
resource "aws_subnet" "mgmt" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.mgmt_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-mgmt-wazuh"
    Role = "siem-monitoring"
  }
}

# Route table Public (WAN -> IGW)
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

resource "aws_route_table_association" "public_wan_b" {
  subnet_id      = aws_subnet.public_wan_b.id
  route_table_id = aws_route_table.public.id
}

# Route table Private A (AZ-a: K8s Subnet A & Management Subnet Wazuh -> Gateway 1 LAN ENI)
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rt-private-a"
  }
}

resource "aws_route_table_association" "private_k8s" {
  subnet_id      = aws_subnet.private_k8s.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.private_a.id
}

# Route table Private B (AZ-b: K8s Subnet B -> Gateway 2 LAN ENI)
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rt-private-b"
  }
}

resource "aws_route_table_association" "private_k8s_b" {
  subnet_id      = aws_subnet.private_k8s_b.id
  route_table_id = aws_route_table.private_b.id
}

# 4. VPC Flow Logs (CIS AWS Benchmark)
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-flow-logs"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-vpc-flow-logs-role"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-vpc-flow-log"
  }
}

