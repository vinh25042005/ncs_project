# NCS Project: Microservices Security, Upstream Kubernetes, Gateway & Wazuh SIEM

---

## 1. Kiến trúc tổng thể (Defense-in-Depth)

```
                             [ Attacker / Internet ]
                                        │
                                        ▼
             ┌─────────────────────────────────────────────────────┐
             │         AWS Network Load Balancer (NLB L4)          │
             │  • DNS: ncs-project-nlb-fa5afa04f4f63ce1...         │
             │  • Ports: 80 (HTTP), 443 (HTTPS), 7443, 8443        │
             │  • Active-Active High Availability across 2 AZs     │
             └──────────────┬────────────────────────┬─────────────┘
                            │                        │
               ┌────────────┴───────────┐┌───────────┴────────────┐
               │    GATEWAY 1 (AZ-a)    ││    GATEWAY 2 (AZ-b)    │
               │ • WAN IP: 13.251.225.100││ • WAN IP: 18.140.131.125│
               │ • LAN IP: 10.0.10.254  ││ • LAN IP: 10.0.11.254  │
               │ • Suricata IDS/IPS DPI ││ • Suricata IDS/IPS DPI │
               │ • DNAT & LAN MASQ HA   ││ • DNAT & LAN MASQ HA   │
               └────────────┬───────────┘└───────────┬────────────┘
                            │                        │
         ┌──────────────────┴────────────────────────┴──────────────────┐
         │                  VPC SUBNETS (10.0.0.0/16)                   │
         │                                                              │
         │  [AZ-a Private Subnet: 10.0.10.0/24]                         │
         │   • k8s-master: 10.0.10.10 (c7i-flex.large)                  │
         │     - Ingress-NGINX (80/443), Rancher Server (NodePort 30443)│
         │   • k8s-worker-1: 10.0.10.139 (t3.small)                     │
         │                                                              │
         │  [AZ-b Private Subnet: 10.0.11.0/24]                         │
         │   • k8s-worker-2: 10.0.11.21 (t3.small)                      │
         │                                                              │
         │  [Management Subnet: 10.0.20.0/24 (AZ-a)]                    │
         │   • wazuh-siem: 10.0.20.10 (t3.small)                        │
         │     - Wazuh Manager v4.14.9, REST API Port 55000 (NLB: 8443) │
         └──────────────────────────────────────────────────────────────┘
```

---

## 2. Cấu trúc thư mục

```text
project_ncs/
├── scripts/
│   └── deploy-k8s.sh                  # Script triển khai tự động toàn bộ hạ tầng & app
├── k8s/                               # Toàn bộ Kubernetes Manifests
│   ├── kustomization.yaml             # Kustomize config (namespace: online-boutique)
│   ├── 00-namespace.yaml              # Namespace online-boutique kèm nhãn PSA
│   ├── 01-online-boutique.yaml        # Microservices Online Boutique (Deployments, Services, SAs)
│   ├── 02-ingress.yaml                # Nginx Ingress routing to frontend kèm TLS
│   ├── 03-hpa.yaml                    # Horizontal Pod Autoscalers (Frontend, Cart, Checkout)
│   ├── 04-network-policies.yaml       # Zero-Trust inter-service network isolation
│   ├── 05-rancher-service.yaml        # NodePort service cho Rancher management
│   ├── 06-pdb.yaml                    # PodDisruptionBudgets (maxUnavailable: 1)
│   ├── 07-resource-quota.yaml         # ResourceQuota và LimitRange biên trên/dưới
│   └── internal-tools/                # Namespace phụ và podinfo thử nghiệm cô lập
├── ansible/                           # Tự động hóa hạ tầng (Kubeadm, Hardening, Boutique)
│   ├── site.yml                       # Playbook chính bootstrap K8s Master & Workers
│   ├── ansible.cfg                    # Cấu hình tối ưu kết nối SSH & roles
│   ├── inventory.ini                  # Inventory chạy từ máy cá nhân (SSH ProxyJump)
│   ├── inventory-bastion.ini          # Inventory chạy trực tiếp trên Gateway Bastion
│   └── roles/
│       ├── common/                    # Chuẩn bị OS, kernel modules, containerd, kubelet
│       ├── gateway/                   # Suricata IDS/IPS, iptables NAT/DNAT và chuyển tiếp
│       ├── master/                    # Kubeadm init v1beta4, audit policy, Flannel CNI
│       ├── worker/                    # Kubeadm join cluster
│       ├── ingress/                   # Nginx Ingress Controller bare-metal
│       ├── metrics_server/            # Metrics-Server phục vụ HPA và kubectl top
│       ├── kubernetes_dashboard/      # Kubernetes Dashboard Web UI & admin token
│       ├── netpol_enforcer/           # Bộ thi hành NetworkPolicy cho Flannel
│       ├── online_boutique/           # Triển khai ứng dụng Online Boutique và HPA
│       ├── wazuh_manager/             # Wazuh Manager & phân tích K8s audit log
│       └── wazuh_agent/               # Wazuh Agent & tích hợp Suricata eve.json
├── docs/                              # Tài liệu & sơ đồ kiến trúc
│   ├── BAO_CAO_TRIEN_KHAI.md          # Báo cáo triển khai kỹ thuật chi tiết
│   ├── architecture_diagram.svg       # Sơ đồ kiến trúc Vector SVG
│   └── architecture_diagram.png       # Sơ đồ kiến trúc PNG
├── latex_report/                      # Báo cáo nghiên cứu học thuật định dạng LaTeX
├── terraform/                         # Hạ tầng đám mây AWS (Terraform IaC)
│   ├── main.tf                        # Root module điều phối các modules
│   ├── variables.tf                   # Biến đầu vào kèm validation
│   ├── outputs.tf                     # Các output endpoint và IP
│   ├── versions.tf                    # Provider AWS, Local & S3 backend
│   ├── inventory.tf                   # Tự động sinh file Ansible inventory
│   ├── tf-s3.sh                       # Script đồng bộ tfvars an toàn qua S3
│   └── modules/
│       ├── network/                   # VPC Multi-AZ, Subnets WAN/LAN/Mgmt, Route Tables
│       ├── security/                  # Security Groups cho Gateway và K8s
│       └── compute/                   # EC2 Instances, Dual-ENI Netplan, IMDSv2
└── README.md
```

---

## 3. Các Microservices trong Google Online Boutique

Hệ thống bao gồm 11 vi dịch vụ độc lập cùng bộ sinh tải:
* **frontend**: Giao diện web người dùng (Go/HTML).
* **cartservice**: Quản lý giỏ hàng (C# / .NET).
* **redis-cart**: Cơ sở dữ liệu cache lưu giỏ hàng (Redis).
* **productcatalogservice**: Danh mục sản phẩm (Go).
* **currencyservice**: Chuyển đổi tỷ giá tiền tệ (Node.js).
* **paymentservice**: Xử lý thanh toán thẻ (Node.js).
* **shippingservice**: Tính phí vận chuyển (Go).
* **emailservice**: Gửi email xác nhận đơn hàng (Python).
* **checkoutservice**: Điều phối quy trình đặt hàng (Go).
* **recommendationservice**: Gợi ý sản phẩm liên quan (Python).
* **adservice**: Phân phối banner quảng cáo (Java).
* **loadgenerator**: Mô phỏng lượng người dùng truy cập và mua hàng liên tục.

---

## 4. Chính sách mạng cô lập (Network Policies - Zero-Trust)

Toàn bộ namespace `online-boutique` áp dụng nguyên tắc **Default Deny**:
* Mọi traffic inbound mặc định bị DROP.
* Chỉ mở chính xác các luồng kết nối cần thiết giữa các microservices:
  * Ingress Nginx ➔ `frontend` (Port 8080).
  * `frontend` ➔ `cartservice`, `recommendationservice`, `productcatalogservice`, `checkoutservice`, `shippingservice`, `adservice`.
  * `checkoutservice` ➔ `paymentservice`, `emailservice` (Port 8080), `currencyservice`, `shippingservice`, `productcatalogservice`, `cartservice`.
  * `cartservice` ➔ `redis-cart` (Port 6379). **Tuyệt đối không cho phép frontend hay các service khác truy cập trực tiếp vào Redis hoặc Payment**.

---

## 5. Hướng dẫn Triển khai

### Cách 1: Tự động hóa toàn bộ bằng Script (Khuyến nghị)
```bash
bash scripts/deploy-k8s.sh
```

### Cách 2: Triển khai thủ công từng bước

#### Bước 1: Triển khai hạ tầng đám mây qua Terraform
```bash
cd terraform/
terraform init
terraform apply -auto-approve
```

#### Bước 2: Cài đặt cụm Kubernetes qua Ansible
Từ máy làm việc cá nhân (thông qua Bastion SSH ProxyJump):
```bash
cd ansible/
ansible-playbook -i inventory.ini site.yml
```

#### Bước 3: Kiểm tra trạng thái cụm K8s
Lấy địa chỉ IP Gateway:
```bash
GATEWAY_IP=$(cd terraform && terraform output -raw pfsense_firewall_public_ip)
ssh -i ~/.ssh/ncs-key.pem -J ubuntu@"$GATEWAY_IP" ubuntu@10.0.10.10
```
Trên Master node:
```bash
kubectl get nodes -o wide
kubectl get pods -n online-boutique
kubectl get hpa -n online-boutique
```
