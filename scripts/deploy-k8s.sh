#!/bin/bash
set -euo pipefail
# Script tự động triển khai toàn bộ hệ thống: Terraform + Ansible Kubeadm K8s

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/ncs-key.pem}"

if [ ! -f "$SSH_KEY" ]; then
  echo ">> LỖI: Không tìm thấy SSH private key tại: $SSH_KEY" >&2
  echo ">> Vui lòng tạo hoặc đặt đường dẫn chính xác qua biến môi trường SSH_KEY." >&2
  exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"

echo "=========================================================="
echo ">> BƯỚC 1: KHỞI TẠO HẠ TẦNG VỚI TERRAFORM..."
echo "=========================================================="
cd "$ROOT_DIR/terraform"
if [ ! -d ".terraform" ]; then
  echo ">> Khởi tạo Terraform provider plugins..."
  terraform init
fi
terraform apply -auto-approve

PFSENSE_IP=$(terraform output -raw pfsense_firewall_public_ip)
if [ -z "$PFSENSE_IP" ] || [ "$PFSENSE_IP" = "None" ]; then
  echo ">> LỖI: Không lấy được địa chỉ Public IP của Gateway từ Terraform output!" >&2
  exit 1
fi
echo ">> Gateway Public IP: $PFSENSE_IP"

echo "=========================================================="
echo ">> BƯỚC 2: ĐỢI GATEWAY SẴN SÀNG KẾT NỐI SSH..."
echo "=========================================================="
MAX_RETRIES=30
COUNT=0
until ssh $SSH_OPTS -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "uptime" >/dev/null 2>&1; do
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
    echo ">> LỖI: Quá thời gian chờ kết nối SSH tới Gateway ($PFSENSE_IP) sau $((MAX_RETRIES * 5))s!" >&2
    exit 1
  fi
  echo "Đang đợi Gateway SSH ($PFSENSE_IP)... ($COUNT/$MAX_RETRIES)"
  sleep 5
done

echo ">> Gateway SSH đã sẵn sàng! Đang đợi hoàn tất cài đặt package (cloud-init)..."
ssh $SSH_OPTS -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "cloud-init status --wait"
echo ">> Gateway và Ansible Controller đã sẵn sàng 100%!"

# Thiết lập cơ chế tự động dọn dẹp khóa private key trên Gateway khi script hoàn tất hoặc bị ngắt
cleanup() {
  echo ">> Đang thu hồi & dọn dẹp SSH private key tạm thời trên Gateway..."
  ssh $SSH_OPTS -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "rm -f ~/.ssh/ncs-key.pem" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "=========================================================="
echo ">> BƯỚC 3: ĐỒNG BỘ MÃ NGUỒN ANSIBLE LÊN BASTION GATEWAY..."
echo "=========================================================="
ssh $SSH_OPTS -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "mkdir -p ~/ansible_deploy/k8s ~/.ssh"
scp $SSH_OPTS -i "$SSH_KEY" "$SSH_KEY" ubuntu@"$PFSENSE_IP":~/.ssh/ncs-key.pem
ssh $SSH_OPTS -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "chmod 600 ~/.ssh/ncs-key.pem"

scp -r $SSH_OPTS -i "$SSH_KEY" "$ROOT_DIR/ansible/"* ubuntu@"$PFSENSE_IP":~/ansible_deploy/
scp -r $SSH_OPTS -i "$SSH_KEY" "$ROOT_DIR/k8s/"* ubuntu@"$PFSENSE_IP":~/ansible_deploy/k8s/

echo "=========================================================="
echo ">> BƯỚC 4: THỰC THI ANSIBLE PLAYBOOK CÀI ĐẶT K8S GỐC..."
echo "=========================================================="
TTY_FLAG=""
[ -t 1 ] && TTY_FLAG="-t"
ANSIBLE_EXTRA_ARGS="${*:-}"
ssh $TTY_FLAG $SSH_OPTS -i "$SSH_KEY" ubuntu@"$PFSENSE_IP" "cd ~/ansible_deploy && ansible-playbook -i inventory-bastion.ini site.yml $ANSIBLE_EXTRA_ARGS"

echo "=========================================================="
echo ">> BƯỚC 5: KIỂM THỬ TRUY CẬP WEBSITE QUA AWS NLB & GATEWAY..."
echo "=========================================================="
NLB_DNS=$(terraform output -raw nlb_dns_name 2>/dev/null || true)
TEST_ENDPOINT="${NLB_DNS:-$PFSENSE_IP}"
echo ">> Đang kiểm tra sức khỏe ứng dụng Online Boutique qua: http://$TEST_ENDPOINT/..."

READY=0
for i in $(seq 1 24); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$TEST_ENDPOINT/" || true)
  if [ "$HTTP_CODE" = "200" ]; then
    READY=1
    echo ">> Website Online Boutique đã sẵn sàng! HTTP Status: $HTTP_CODE"
    break
  fi
  echo ">> Chờ ứng dụng sẵn sàng (Hiện tại HTTP: $HTTP_CODE)... thử lại sau 5s ($i/24)"
  sleep 5
done

if [ "$READY" -ne 1 ]; then
  echo ">> CẢNH BÁO: Ứng dụng chưa trả về HTTP 200 OK sau 120s. Vui lòng kiểm tra pods K8s!" >&2
fi

echo ""
echo "=========================================================="
echo ">> HOÀN THÀNH TRIỂN KHAI HỆ THỐNG DUAL-GATEWAY HA!"
echo ">> Điểm truy cập công khai (AWS NLB):"
echo "   • Online Boutique:        http://$TEST_ENDPOINT/"
echo "   • Wazuh SIEM Dashboard:   https://$TEST_ENDPOINT:8443/"
echo "   • K8s/Rancher Dashboard:  https://$TEST_ENDPOINT:7443/"
echo ">> Gateway 1 IP (AZ-a):      $PFSENSE_IP"
PFSENSE_2_IP=$(terraform output -raw pfsense_2_public_ip 2>/dev/null || true)
echo ">> Gateway 2 IP (AZ-b):      ${PFSENSE_2_IP:-N/A}"
echo "=========================================================="
