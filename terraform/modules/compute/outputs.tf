output "pfsense_public_ip" {
  value = aws_eip.pfsense.public_ip
}

output "pfsense_lan_ip" {
  value = var.pfsense_lan_ip
}

output "pfsense_lan_eni_id" {
  value = aws_network_interface.pfsense_lan.id
}

output "k3s_master_private_ip" {
  value = aws_instance.k3s_master.private_ip
}

output "k3s_worker_private_ips" {
  value = aws_instance.k3s_worker[*].private_ip
}

output "wazuh_public_ip" {
  value = aws_instance.wazuh.public_ip
}

output "wazuh_private_ip" {
  value = aws_instance.wazuh.private_ip
}
