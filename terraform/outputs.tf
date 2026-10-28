output "nlb_dns_name" {
  description = "DNS endpoint công khai của AWS Network Load Balancer (Multi-AZ Active-Active)"
  value       = module.compute.nlb_dns_name
}

output "pfsense_firewall_public_ip" {
  description = "Địa chỉ Elastic IP của Gateway 1 (AZ-a)"
  value       = module.compute.pfsense_public_ip
}

output "pfsense_2_public_ip" {
  description = "Địa chỉ Elastic IP của Gateway 2 (AZ-b)"
  value       = module.compute.pfsense_2_public_ip
}

output "pfsense_firewall_lan_ip" {
  description = "IP LAN của Gateway 1 (Default Gateway K8s AZ-a & Mgmt)"
  value       = module.compute.pfsense_lan_ip
}

output "pfsense_2_lan_ip" {
  description = "IP LAN của Gateway 2 (Default Gateway K8s AZ-b)"
  value       = module.compute.pfsense_2_lan_ip
}

output "wazuh_siem_private_ip" {
  description = "IP nội bộ của Dedicated Wazuh SIEM Server"
  value       = module.compute.wazuh_private_ip
}

output "boutique_web_url" {
  description = "URL truy cập trực tiếp Google Online Boutique qua AWS NLB"
  value       = "http://${module.compute.nlb_dns_name}"
}

output "rancher_dashboard_url" {
  description = "URL truy cập Rancher Management Dashboard qua AWS NLB (Port 7443)"
  value       = "https://${module.compute.nlb_dns_name}:7443"
}

output "wazuh_siem_dashboard_url" {
  description = "URL truy cập Wazuh SIEM Dashboard qua AWS NLB (Port 8443)"
  value       = "https://${module.compute.nlb_dns_name}:8443"
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
    pfsense_gateway_1 = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.compute.pfsense_public_ip}"
    pfsense_gateway_2 = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.compute.pfsense_2_public_ip}"
    wazuh_siem        = "ssh -i ~/.ssh/${var.key_name}.pem -J ubuntu@${module.compute.pfsense_public_ip} ubuntu@${module.compute.wazuh_private_ip}"
    k8s_master        = "ssh -i ~/.ssh/${var.key_name}.pem -J ubuntu@${module.compute.pfsense_public_ip} ubuntu@${module.compute.k8s_master_private_ip}"
  }
}
