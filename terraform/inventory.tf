# Tự động sinh Ansible Inventory sau khi Terraform tạo xong hạ tầng EC2

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0600"
  content         = <<-EOF

[gateway]
pfsense-gateway-1 ansible_host=${module.compute.pfsense_public_ip}
pfsense-gateway-2 ansible_host=${module.compute.pfsense_2_public_ip}

[wazuh]
wazuh-siem ansible_host=${module.compute.wazuh_private_ip}

[master]
k8s-master ansible_host=${module.compute.k8s_master_private_ip}

[workers]
%{for idx, ip in module.compute.k8s_worker_private_ips~}
k8s-worker-${idx + 1} ansible_host=${ip}
%{endfor~}

[k8s_cluster:children]
master
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem

[k8s_cluster:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new -o ProxyCommand="ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/${var.key_name}.pem -W %h:%p ubuntu@${module.compute.pfsense_public_ip}"'

[wazuh:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new -o ProxyCommand="ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/${var.key_name}.pem -W %h:%p ubuntu@${module.compute.pfsense_public_ip}"'
EOF
}

resource "local_file" "ansible_inventory_bastion" {
  filename        = "${path.module}/../ansible/inventory-bastion.ini"
  file_permission = "0600"
  content         = <<-EOF

[gateway]
pfsense-gateway-1 ansible_host=localhost ansible_connection=local
pfsense-gateway-2 ansible_host=${module.compute.pfsense_2_lan_ip}

[wazuh]
wazuh-siem ansible_host=${module.compute.wazuh_private_ip}

[master]
k8s-master ansible_host=${module.compute.k8s_master_private_ip}

[workers]
%{for idx, ip in module.compute.k8s_worker_private_ips~}
k8s-worker-${idx + 1} ansible_host=${ip}
%{endfor~}

[k8s_cluster:children]
master
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
EOF
}
