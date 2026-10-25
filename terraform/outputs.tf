output "pfsense_firewall_public_ip" {
  description = "Địa chỉ Public IP (EIP) của tường lửa pfSense (cổng đón toàn bộ traffic Internet)"
  value       = module.compute.pfsense_public_ip
}

output "pfsense_firewall_lan_ip" {
  description = "IP LAN của pfSense (Làm Default Gateway cho K8s Cluster)"
  value       = module.compute.pfsense_lan_ip
}

output "boutique_web_url" {
  description = "URL truy cập trực tiếp Google Online Boutique"
  value       = "http://${module.compute.pfsense_public_ip}"
}

output "rancher_dashboard_url" {
  description = "URL truy cập Rancher Management Dashboard trên cụm K8s (qua Gateway Port 7443)"
  value       = "https://${module.compute.pfsense_public_ip}:7443"
}

output "wazuh_siem_dashboard_url" {
  description = "URL truy cập Wazuh SIEM Dashboard (qua Gateway Port 8443)"
  value       = "https://${module.compute.pfsense_public_ip}:8443"
}

output "k8s_master_private_ip" {
  description = "IP nội bộ của Kubernetes Master (truy cập qua Gateway Bastion / ProxyJump)"
  value       = module.compute.k8s_master_private_ip
}

output "k8s_worker_private_ips" {
  description = "IP nội bộ của Kubernetes Workers"
  value       = module.compute.k8s_worker_private_ips
}

output "ssh_commands" {
  description = "Lệnh SSH mẫu"
  value = {
    pfsense_gateway = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.compute.pfsense_public_ip}"
    k8s_master      = "ssh -i ~/.ssh/${var.key_name}.pem -J ubuntu@${module.compute.pfsense_public_ip} ubuntu@${module.compute.k8s_master_private_ip}"
  }
}
