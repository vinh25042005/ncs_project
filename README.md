# NCS Project: Microservices Security, K3s, pfSense & SIEM/SOAR

Hệ thống vận hành kiến trúc Microservices hiện đại trên cụm Kubernetes rút gọn (K3s), được bảo vệ đa tầng bởi tường lửa biên pfSense (Suricata IDS/IPS), cô lập luồng mạng bằng Kubernetes Network Policies (Zero-Trust) và giám sát, ứng phó tự động với Wazuh SIEM & SOAR.

---

## 1. Kiến trúc tổng thể (Defense-in-Depth)

```
                            [ Attacker / Internet ]
                                       │
                                       ▼
               ┌────────────────────────────────────────────────┐
               │         pfSense FIREWALL & IDS/IPS             │
               │  • WAN IP: 192.168.100.203                     │
               │  • Suricata IDS/IPS: Deep Packet Inspection    │
               │  • Port Forward 80/443 ──► K8s Ingress         │
               └───────────────────────┬────────────────────────┘
                                       │ Mạng LAN Nội bộ (192.168.94.0/24)
                                       ▼
               ┌────────────────────────────────────────────────┐
               │           KUBERNETES CLUSTER (K3s)             │
               │  • Nginx Ingress Controller (L7 Routing)       │
               │  • Workload: Google Online Boutique (11 SVs)   │
               │  • Autoscaling: HPA v2 (CPU Target 70-75%)     │
               │  • Zero-Trust: Network Policies (Default Deny) │
               │  • Audit Logging: K8s API Server Audit Log     │
               └───────────────────────┬────────────────────────┘
                                       │ Logs (Suricata + K8s Audit + Syslog)
                                       ▼
               ┌────────────────────────────────────────────────┐
               │            WAZUH SIEM & SOAR                   │
               │  • Phân tích tương quan sự kiện an ninh        │
               │  • Active Response: Tự động chặn IP trên       │
               │    pfSense khi phát hiện quét lỗ hổng/tấn công │
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
├── ansible/                           # Tự động hóa hạ tầng (K3s, Hardening, Wazuh)
│   ├── playbooks/
│   └── roles/
└── README.md
```

---

## 3. Các Microservices trong Google Online Boutique

Hệ thống bao gồm 11 vi dịch vụ độc lập:
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

---

## 4. Chính sách An toàn mạng (Network Policies - Zero-Trust)

Toàn bộ namespace `online-boutique` áp dụng nguyên tắc **Default Deny**:
* Mọi traffic inbound mặc định bị DROP.
* Chỉ mở chính xác các luồng kết nối cần thiết giữa các microservices:
  * Ingress Nginx ➔ `frontend` (Port 8080).
  * `frontend` ➔ `cartservice`, `recommendationservice`, `productcatalogservice`, `checkoutservice`, `shippingservice`, `adservice`.
  * `checkoutservice` ➔ `paymentservice`, `emailservice`, `currencyservice`, `shippingservice`, `productcatalogservice`, `cartservice`.
  * `cartservice` ➔ `redis-cart` (Port 6379). **Tuyệt đối không cho phép frontend hay các service khác truy cập trực tiếp vào Redis hoặc Payment**.

---

## 5. Hướng dẫn Triển khai nhanh

### Bước 1: Khởi tạo S3 Remote State & DynamoDB Locking (Chống xung đột 2 người apply cùng lúc)
Trước khi chạy dự án chính, khởi tạo bucket S3 và bảng DynamoDB quản lý Lock:
```bash
cd terraform/bootstrap/
terraform init
terraform apply
```
*Lấy tên `s3_bucket_name` và `dynamodb_table_name` được xuất ra để điền vào block `backend "s3"` trong `terraform/main.tf`.*

### Bước 2: Quản lý biến `.tfvars` trên S3 & Triển khai hạ tầng chính
Để cả nhóm dùng chung biến mà không cần commit mật khẩu lên Git:
```bash
cd terraform/

# 1. Đẩy file biến lên S3 (chỉ làm 1 lần hoặc khi có thay đổi)
./tf-s3.sh push-vars

# 2. Khởi tạo backend S3
terraform init

# 3. Chạy apply trực tiếp nạp biến từ S3 (có cơ chế Lock qua DynamoDB)
./tf-s3.sh apply
```
*Khi có người đang `apply`, người thứ 2 cố tình chạy sẽ bị DynamoDB báo lỗi `Error acquiring the state lock` và chặn lại ngay lập tức.*

*Terraform sẽ tự động tạo:*
- **VPC** 3 tầng mạng: WAN (Public), K3s (Private), Wazuh (Management).
- **pfSense / Security Gateway** (Dual-ENI: WAN có Elastic IP, LAN làm Gateway cho K3s).
- **Cụm K3s (Master + Worker)** trong mạng Private, kích hoạt sẵn K8s API Audit Logging.
- **Wazuh SIEM Server** thu thập log và bảng điều khiển SOC.

---

### Bước 2: Triển khai toàn bộ ứng dụng lên K3s
Trên máy chủ K3s Master:
```bash
# Triển khai toàn bộ 11 microservices + Ingress + HPA + Network Policies
kubectl apply -k k8s/

# Kiểm tra trạng thái
kubectl get pods,svc,ingress,hpa,networkpolicy -n online-boutique
```

