output "pfsense_sg_id" {
  description = "ID của Security Group dành cho tường lửa pfSense"
  value       = aws_security_group.pfsense.id
}

output "k3s_sg_id" {
  description = "ID của Security Group dành cho các node K3s"
  value       = aws_security_group.k3s.id
}

output "wazuh_sg_id" {
  description = "ID của Security Group dành cho máy chủ Wazuh SIEM"
  value       = aws_security_group.wazuh.id
}

output "rancher_sg_id" {
  description = "ID của Security Group dành cho máy chủ Rancher Management"
  value       = aws_security_group.rancher.id
}
