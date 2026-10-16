output "pfsense_firewall_public_ip" {
  description = "Địa chỉ Public IP (EIP) của tường lửa pfSense (cổng đón toàn bộ traffic Internet)"
  value       = module.compute.pfsense_public_ip
}

output "pfsense_firewall_lan_ip" {
  description = "IP LAN của pfSense (Làm Default Gateway cho K3s Cluster)"
  value       = module.compute.pfsense_lan_ip
}

output "wazuh_siem_dashboard_url" {
  description = "URL truy cập Wazuh SIEM Dashboard"
  value       = "https://${module.compute.wazuh_public_ip}"
}

output "k3s_master_private_ip" {
  description = "IP nội bộ của K3s Master (chỉ truy cập được từ sau pfSense hoặc VPN)"
  value       = module.compute.k3s_master_private_ip
}

output "k3s_worker_private_ips" {
  description = "IP nội bộ của K3s Workers"
  value       = module.compute.k3s_worker_private_ips
}

output "ssh_commands" {
  description = "Lệnh SSH mẫu"
  value = {
    pfsense_gateway = "ssh -i ${var.key_name}.pem admin@${module.compute.pfsense_public_ip}"
    wazuh_siem      = "ssh -i ${var.key_name}.pem ubuntu@${module.compute.wazuh_public_ip}"
    k3s_master      = "ssh -i ${var.key_name}.pem -J ubuntu@${module.compute.wazuh_public_ip} ubuntu@${module.compute.k3s_master_private_ip}"
  }
}
