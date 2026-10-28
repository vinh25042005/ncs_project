output "pfsense_public_ip" {
  description = "Địa chỉ Elastic IP của Gateway 1 (AZ-a)"
  value       = aws_eip.pfsense.public_ip
}

output "pfsense_lan_ip" {
  description = "Địa chỉ IP cổng LAN của Gateway 1 trong mạng nội bộ K8s AZ-a"
  value       = var.pfsense_lan_ip
}

output "pfsense_lan_eni_id" {
  description = "ID của card mạng LAN Gateway 1 dùng để cấu hình default route cho Private Route Table A"
  value       = aws_network_interface.pfsense_lan.id
}

output "pfsense_2_public_ip" {
  description = "Địa chỉ Elastic IP của Gateway 2 (AZ-b)"
  value       = aws_eip.pfsense_2.public_ip
}

output "pfsense_2_lan_ip" {
  description = "Địa chỉ IP cổng LAN của Gateway 2 trong mạng nội bộ K8s AZ-b"
  value       = var.pfsense_2_lan_ip
}

output "pfsense_2_lan_eni_id" {
  description = "ID của card mạng LAN Gateway 2 dùng để cấu hình default route cho Private Route Table B"
  value       = aws_network_interface.pfsense_2_lan.id
}

output "nlb_dns_name" {
  description = "DNS endpoint của AWS Network Load Balancer (Điểm truy cập công khai duy nhất)"
  value       = aws_lb.nlb.dns_name
}

output "wazuh_private_ip" {
  description = "Địa chỉ IP nội bộ của máy chủ Wazuh SIEM"
  value       = aws_instance.wazuh.private_ip
}

output "k8s_master_private_ip" {
  description = "Địa chỉ IP nội bộ của Kubernetes Master Node"
  value       = aws_instance.k8s_master.private_ip
}

output "k8s_worker_private_ips" {
  description = "Danh sách IP nội bộ của các Kubernetes Worker Nodes"
  value       = aws_instance.k8s_worker[*].private_ip
}
