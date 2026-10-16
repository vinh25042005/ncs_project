output "pfsense_public_ip" {
  description = "Địa chỉ Elastic IP của pfSense Firewall"
  value       = aws_eip.pfsense.public_ip
}

output "pfsense_lan_ip" {
  description = "Địa chỉ IP cổng LAN của pfSense trong mạng nội bộ K3s"
  value       = var.pfsense_lan_ip
}

output "pfsense_lan_eni_id" {
  description = "ID của card mạng LAN pfSense dùng để cấu hình default route cho Private Route Table"
  value       = aws_network_interface.pfsense_lan.id
}

output "k3s_master_private_ip" {
  description = "Địa chỉ IP nội bộ của K3s Master Node"
  value       = aws_instance.k3s_master.private_ip
}

output "k3s_worker_private_ips" {
  description = "Danh sách IP nội bộ của các K3s Worker Nodes"
  value       = aws_instance.k3s_worker[*].private_ip
}

output "wazuh_public_ip" {
  description = "Địa chỉ Public IP của máy chủ Wazuh SIEM"
  value       = aws_instance.wazuh.public_ip
}

output "wazuh_private_ip" {
  description = "Địa chỉ Private IP của máy chủ Wazuh SIEM trong VPC"
  value       = aws_instance.wazuh.private_ip
}
