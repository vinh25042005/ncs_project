output "pfsense_public_ip" {
  description = "Địa chỉ Elastic IP của pfSense Firewall"
  value       = aws_eip.pfsense.public_ip
}

output "pfsense_lan_ip" {
  description = "Địa chỉ IP cổng LAN của pfSense trong mạng nội bộ K8s"
  value       = var.pfsense_lan_ip
}

output "pfsense_lan_eni_id" {
  description = "ID của card mạng LAN pfSense dùng để cấu hình default route cho Private Route Table"
  value       = aws_network_interface.pfsense_lan.id
}

output "k8s_master_private_ip" {
  description = "Địa chỉ IP nội bộ của Kubernetes Master Node"
  value       = aws_instance.k8s_master.private_ip
}

output "k8s_worker_private_ips" {
  description = "Danh sách IP nội bộ của các Kubernetes Worker Nodes"
  value       = aws_instance.k8s_worker[*].private_ip
}


