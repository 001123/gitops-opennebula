# 🚀 GitOps OpenNebula Repository

Kho lưu trữ cấu hình GitOps trung tâm quản lý các ứng dụng và hạ tầng trên cụm Kubernetes (OpenNebula / OneKS), vận hành tự động bằng **ArgoCD** và bảo mật bởi **Mozilla SOPS + Age**.

---

## 📁 Cấu trúc thư mục chuẩn

```text
gitops-opennebula/
├── .gitignore                      # Loại trừ private keys, certs và file giải mã
├── .sops.yaml                      # Cấu hình quy tắc mã hóa của SOPS với Public Age Key
├── README.md                       # Hướng dẫn sử dụng & quy trình vận hành
├── bootstrap/                      # Thư mục khởi tạo hệ thống GitOps (App of Apps)
│   ├── root-application.yaml       # ArgoCD Root Application (theo dõi bootstrap/apps/)
│   └── apps/                       # Chứa khai báo Application CRD cho từng ứng dụng
│       └── nginx-demo.yaml         # Application CRD cho ứng dụng Nginx Demo
├── apps/                           # Mã nguồn và manifests triển khai của các ứng dụng
│   └── nginx-demo/                 # Ứng dụng mẫu Nginx Demo
│       ├── application.yaml        # ArgoCD Application định nghĩa cho Nginx Demo
│       └── base/                   # K8s manifests cơ sở
│           ├── kustomization.yaml
│           ├── namespace.yaml      # Namespace `demo-nginx`
│           ├── deployment.yaml     # Nginx Deployment (gắn ConfigMap & Secret)
│           ├── service.yaml        # Service NodePort (Port: 30088)
│           ├── configmap.yaml      # Giao diện HTML tùy biến
│           └── secret.enc.yaml     # Kubernetes Secret đã được MÃ HÓA bằng SOPS + Age
└── scripts/                        # Các script tiện ích hỗ trợ quản trị
    ├── init-age-key.sh             # Sinh cặp khóa Age mới
    ├── encrypt-secret.sh           # Tiện ích mã hóa nhanh file YAML bằng SOPS
    └── decrypt-secret.sh           # Tiện ích giải mã để xem nội dung bí mật
```

---

## 🔐 Cơ chế bảo mật Secret với SOPS + Age

Repository tuân thủ nguyên tắc GitOps: **Không bao giờ commit Secret dạng rõ (plaintext) lên Git**.

- **Public Key của Age**: Được lưu công khai trong file `.sops.yaml`. Bất kỳ ai cũng có thể dùng khóa này để mã hóa file.
- **Private Key của Age**: Được lưu bí mật trên máy quản trị (hoặc quản lý qua Ansible) và nạp vào Kubernetes Secret `sops-age` trong namespace `argocd`. ArgoCD CMP Sidecar sẽ tự động giải mã on-the-fly khi đồng bộ từ Git.

### 1. Mã hóa Secret mới
Tạo file `secret.yaml` chứa thông tin nhạy cảm, sau đó chạy:
```bash
./scripts/encrypt-secret.sh path/to/secret.yaml path/to/secret.enc.yaml
```
> Hoặc chạy trực tiếp:
> ```bash
> sops --encrypt path/to/secret.yaml > path/to/secret.enc.yaml
> ```
*Sau khi mã hóa, bạn xóa file `secret.yaml` và chỉ commit `secret.enc.yaml` lên Git.*

### 2. Xem nội dung Secret đã mã hóa (Giải mã kiểm tra)
```bash
./scripts/decrypt-secret.sh path/to/secret.enc.yaml
```

---

## 🔄 Mô hình App of Apps

1. Khi triển khai lần đầu, bạn chỉ cần nạp **Root Application**:
   ```bash
   kubectl apply -f bootstrap/root-application.yaml
   ```
2. **Root Application** sẽ liên tục giám sát thư mục `bootstrap/apps/`.
3. Khi bạn muốn thêm một dịch vụ mới:
   - Tạo thư mục ứng dụng trong `apps/<ten-ung-dung>/base/`.
   - Tạo file Application CRD trong `bootstrap/apps/<ten-ung-dung>.yaml`.
   - Commit & Push lên Git.
   - ArgoCD sẽ tự động nhận diện và triển khai dịch vụ mới vào cụm K8s mà không cần bất kỳ thao tác thủ công nào trên Web UI.

---

## 🌐 Ứng dụng mẫu: Nginx Demo

Ứng dụng Nginx Demo được định nghĩa sẵn trong `apps/nginx-demo/base/`:
- **Namespace**: `demo-nginx`
- **Port truy cập**: NodePort `30088` (truy cập qua `http://<NODE_IP>:30088`)
- **Tài nguyên**: Deployment, Service, ConfigMap UI tùy biến, Secret `secret.enc.yaml` giải mã tự động.
