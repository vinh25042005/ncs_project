# NCS Project: Microservices Security, Upstream Kubernetes, pfSense & Wazuh SIEM


---

## 1. Kiến trúc tổng thể (Defense-in-Depth)

```
                            [ Attacker / Internet ]
                                       │
                                       ▼
               ┌────────────────────────────────────────────────┐
               │         pfSense FIREWALL & IDS/IPS             │
               │  • WAN IP: 10.0.1.8 (Public EIP: 13.228.8.81)  │
               │  • Suricata IDS/IPS: Deep Packet Inspection    │
               │  • Port Forward 80 ──► K8s Ingress Controller  │
               │  • SSH Bastion Host (Port 22 ──► Jump to K8s)  │
               └───────────────────────┬────────────────────────┘
                                       │ Mạng LAN Nội bộ (10.0.10.0/24 & 10.0.11.0/24)
                                       ▼
               ┌────────────────────────────────────────────────┐
               │         UPSTREAM KUBERNETES CLUSTER            │
               │  • K8s v1.31.14 (Kubeadm) + containerd v2.2.1  │
               │  • Nginx Ingress Controller (Baremetal HostNet)│
               │  • Flannel CNI: VXLAN Overlay (10.244.0.0/16)  │
               │  • Workload: Google Online Boutique (12 SVs)   │
               │  • Autoscaling: HPA v2 (CPU Target 70-75%)     │
               │  • Zero-Trust: Network Policies (Default Deny) │
               │  • Audit Logging: K8s API Server Audit Log     │
               └───────────────────────┬────────────────────────┘
                                       │ Logs (Suricata + K8s Audit + Syslog)
                                       ▼
               ┌────────────────────────────────────────────────┐
               │                 WAZUH SIEM                     │
               │  • IP: 10.0.20.10 (Management Subnet)          │
               │  • Thu thập nhật ký an ninh tập trung          │
               │  • Phân tích tương quan theo MITRE ATT&CK      │
               │  • Cảnh báo thời gian thực & SOC Dashboard     │
               └────────────────────────────────────────────────┘
```

---

## 2. Cấu trúc thư mục

```text
ncs_project/
├── k8s/                               # Toàn bộ Kubernetes Manifests
│   ├── kustomization.yaml             # Kustomize config (namespace: online-boutique)
│   ├── 00-namespace.yaml              # Namespace online-boutique
│   ├── 01-online-boutique.yaml        # 11 Microservices (Deployments, Services, SAs)
│   ├── 02-ingress.yaml                # Nginx Ingress routing to frontend
│   ├── 03-hpa.yaml                    # Horizontal Pod Autoscalers (Frontend, Cart, Checkout)
│   └── 04-network-policies.yaml       # Zero-Trust inter-service network isolation
├── ansible/                           # Tự động hóa hạ tầng (Kubeadm, Hardening, Boutique)
│   ├── site.yml                       # Playbook chính bootstrap K8s Master & Workers
│   ├── inventory.ini                  # Inventory chạy qua SSH Bastion (ProxyJump)
│   ├── inventory-bastion.ini          # Inventory chạy trực tiếp từ pfSense Gateway
│   └── roles/
│       ├── common/                    # Sysctl, swapfile, containerd, kubeadm
│       ├── master/                    # Kubeadm init, Flannel CNI, kubeconfig
│       ├── worker/                    # Kubeadm join cluster
│       ├── ingress/                   # Nginx Ingress baremetal controller
│       └── online_boutique/           # Triển khai Online Boutique manifests
├── docs/                              # Tài liệu & sơ đồ kiến trúc
│   ├── architecture_diagram.svg       # Sơ đồ kiến trúc Vector SVG
│   └── architecture_diagram.png       # Sơ đồ kiến trúc PNG 1920x1350
├── terraform/                         # Hạ tầng đám mây AWS
│   ├── main.tf                        # VPC, Subnets, Gateway, EC2 Instances
│   ├── variables.tf
│   └── outputs.tf
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

## 4.(Network Policies - Zero-Trust)

Toàn bộ namespace `online-boutique` áp dụng nguyên tắc **Default Deny**:
* Mọi traffic inbound mặc định bị DROP.
* Chỉ mở chính xác các luồng kết nối cần thiết giữa các microservices:
  * Ingress Nginx ➔ `frontend` (Port 8080).
  * `frontend` ➔ `cartservice`, `recommendationservice`, `productcatalogservice`, `checkoutservice`, `shippingservice`, `adservice`.
  * `checkoutservice` ➔ `paymentservice`, `emailservice`, `currencyservice`, `shippingservice`, `productcatalogservice`, `cartservice`.
  * `cartservice` ➔ `redis-cart` (Port 6379). **Tuyệt đối không cho phép frontend hay các service khác truy cập trực tiếp vào Redis hoặc Payment**.

---

## 5. Hướng dẫn Triển khai nhanh

### Bước 1: Triển khai hạ tầng qua Terraform
```bash
cd terraform/
terraform init
terraform apply -auto-approve
```

### Bước 2: Cài đặt cụm Kubernetes qua Ansible
```bash
cd ansible/
ansible-playbook -i inventory-bastion.ini site.yml
```

### Bước 3: Kiểm tra trạng thái cụm K8s
```bash
ssh -i ~/.ssh/ncs-key.pem -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/ncs-key.pem ubuntu@13.228.8.81" ubuntu@10.0.10.10
kubectl get nodes -o wide
kubectl get pods -n online-boutique
kubectl get hpa -n online-boutique
```
