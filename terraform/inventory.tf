# Tự động sinh Ansible Inventory sau khi Terraform tạo xong hạ tầng EC2

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOF
# Ansible Inventory for NCS Project K8s Cluster (Kubeadm)
# Tự động sinh bởi Terraform

[gateway]
pfsense-gateway ansible_host=${module.compute.pfsense_public_ip}

[master]
k8s-master ansible_host=${module.compute.k3s_master_private_ip}

[workers]
%{for idx, ip in module.compute.k3s_worker_private_ips~}
k8s-worker-${idx + 1} ansible_host=${ip}
%{endfor~}

[k8s_cluster:children]
master
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${var.key_name}.pem -W %%h:%%p ubuntu@${module.compute.pfsense_public_ip}"'
EOF
}

resource "local_file" "ansible_inventory_bastion" {
  filename        = "${path.module}/../ansible/inventory-bastion.ini"
  file_permission = "0644"
  content         = <<-EOF
# Ansible Inventory chạy trực tiếp từ pfSense Gateway (Không cần ProxyJump)
# Tự động sinh bởi Terraform

[gateway]
pfsense-gateway ansible_host=localhost ansible_connection=local

[master]
k8s-master ansible_host=${module.compute.k3s_master_private_ip}

[workers]
%{for idx, ip in module.compute.k3s_worker_private_ips~}
k8s-worker-${idx + 1} ansible_host=${ip}
%{endfor~}

[k8s_cluster:children]
master
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/${var.key_name}.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
}
