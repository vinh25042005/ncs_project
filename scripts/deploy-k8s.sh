#!/bin/bash
set -e
# Script tự động triển khai toàn bộ hệ thống: Terraform + Ansible Kubeadm K8s

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_KEY="$HOME/.ssh/ncs-key.pem"

echo "=========================================================="
echo ">> BƯỚC 1: KHỞI TẠO HẠ TẦNG VỚI TERRAFORM..."
echo "=========================================================="
cd "$ROOT_DIR/terraform"
terraform apply -auto-approve

PFSENSE_IP=$(terraform output -raw pfsense_firewall_public_ip)
echo ">> pfSense Gateway Public IP: $PFSENSE_IP"

echo "=========================================================="
echo ">> BƯỚC 2: ĐỢI PFSENSE GATEWAY SẴN SÀNG KẾT NỐI SSH..."
echo "=========================================================="
until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "uptime" >/dev/null 2>&1; do
  echo "Đang đợi pfSense SSH ($PFSENSE_IP)..."
  sleep 5
done
echo ">> pfSense Gateway SSH đã sẵn sàng! Đang đợi hoàn tất cài đặt package (cloud-init)..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "cloud-init status --wait"
echo ">> pfSense Gateway và Ansible Controller đã sẵn sàng 100%!"

echo "=========================================================="
echo ">> BƯỚC 3: ĐỒNG BỘ MÃ NGUỒN ANSIBLE LÊN PFSENSE BASTION..."
echo "=========================================================="
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "mkdir -p ~/ansible_deploy/k8s ~/.ssh"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" "$SSH_KEY" ubuntu@"$PFSENSE_IP":~/.ssh/ncs-key.pem
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "chmod 600 ~/.ssh/ncs-key.pem"

scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" "$ROOT_DIR/ansible/"* ubuntu@"$PFSENSE_IP":~/ansible_deploy/
scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" "$ROOT_DIR/k8s/"* ubuntu@"$PFSENSE_IP":~/ansible_deploy/k8s/

echo "=========================================================="
echo ">> BƯỚC 4: THỰC THI ANSIBLE PLAYBOOK CÀI ĐẶT K8S GỐC..."
echo "=========================================================="
ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "cd ~/ansible_deploy && ansible-playbook -i inventory-bastion.ini site.yml"

echo "=========================================================="
echo ">> BƯỚC 5: KIỂM THỬ TRUY CẬP WEBSITE ONLINE BOUTIQUE..."
echo "=========================================================="
sleep 10
curl -s -I "http://$PFSENSE_IP/" | head -n 5

echo ""
echo "=========================================================="
echo ">> HOÀN THÀNH TRIỂN KHAI HỆ THỐNG!"
echo ">> Truy cập web: http://$PFSENSE_IP/"
echo "=========================================================="
