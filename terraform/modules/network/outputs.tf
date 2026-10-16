output "vpc_id" {
  description = "ID của VPC ncs-project"
  value       = aws_vpc.main.id
}

output "public_wan_subnet_id" {
  description = "ID của Public Subnet (WAN) dành cho pfSense"
  value       = aws_subnet.public_wan.id
}

output "public_wan_subnet_b_id" {
  description = "ID của Public Subnet (WAN AZ-b)"
  value       = aws_subnet.public_wan_b.id
}

output "private_k8s_subnet_id" {
  description = "ID của Private Subnet (LAN AZ-a) dành cho K3s Cluster"
  value       = aws_subnet.private_k8s.id
}

output "private_k8s_subnet_b_id" {
  description = "ID của Private Subnet (LAN AZ-b) dành cho K3s Worker Node thứ 2"
  value       = aws_subnet.private_k8s_b.id
}

output "mgmt_subnet_id" {
  description = "ID của Management Subnet dành cho Wazuh SIEM"
  value       = aws_subnet.mgmt.id
}

output "private_route_table_id" {
  description = "ID của bảng định tuyến Private Route Table"
  value       = aws_route_table.private.id
}
