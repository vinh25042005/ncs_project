output "pfsense_firewall_public_ip" {
  description = "Địa chỉ Public IP (EIP) của tường lửa pfSense (cổng đón toàn bộ traffic Internet)"
  value       = module.compute.pfsense_public_ip
}

output "pfsense_firewall_lan_ip" {
  description = "IP LAN của pfSense (Làm Default Gateway cho K3s Cluster)"
  value       = module.compute.pfsense_lan_ip
}

output "boutique_web_url" {
  description = "URL truy cập trực tiếp Google Online Boutique"
  value       = "http://${module.compute.pfsense_public_ip}"
}

output "rancher_k3s_dashboard_url" {
  description = "URL truy cập Rancher Dashboard trên cụm K3s"
  value       = "https://rancher.lab (Trỏ domain rancher.lab về IP ${module.compute.pfsense_public_ip} trong /etc/hosts)"
}

output "wazuh_siem_dashboard_url" {
  description = "URL truy cập Wazuh SIEM Dashboard"
  value       = var.enable_wazuh ? "https://${module.compute.wazuh_public_ip}" : "Tắt để tối ưu 8 vCPUs cho 2 K3s Workers"
}

output "rancher_vm_dashboard_url" {
  description = "URL truy cập Rancher VM riêng biệt (nếu bật)"
  value       = var.enable_rancher_vm ? "https://${module.compute.rancher_public_ip}" : "Đang chạy trực tiếp trên K3s Cluster"
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
    pfsense_gateway = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.compute.pfsense_public_ip}"
    rancher_server  = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.compute.rancher_public_ip}"
    wazuh_siem      = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.compute.wazuh_public_ip}"
    k3s_master      = "ssh -i ~/.ssh/${var.key_name}.pem -J ubuntu@${module.compute.pfsense_public_ip} ubuntu@${module.compute.k3s_master_private_ip}"
  }
}
