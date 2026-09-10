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
│       ├── nginx-demo.yaml         # Application CRD cho ứng dụng Nginx Demo
│       └── monitoring.yaml         # Helm chart + Git values/manifests SOPS
├── apps/                           # Mã nguồn và manifests triển khai của các ứng dụng
│   ├── nginx-demo/                 # Ứng dụng mẫu Nginx Demo
│   │   ├── application.yaml        # ArgoCD Application định nghĩa cho Nginx Demo
│   │   └── base/                   # K8s manifests cơ sở
│   │       ├── kustomization.yaml
│   │       ├── namespace.yaml      # Namespace `demo-nginx`
│   │       ├── deployment.yaml     # Nginx Deployment (gắn ConfigMap & Secret)
│   │       ├── service.yaml        # Service NodePort (Port: 30088)
│   │       ├── configmap.yaml      # Giao diện HTML tùy biến
│   │       └── secret.enc.yaml     # Secret mã hóa SOPS + Age
│   └── monitoring/
│       ├── values.yaml             # Cấu hình kube-prometheus-stack cho dev
│       └── base/
│           ├── kustomization.yaml
│           ├── namespace.yaml      # Namespace `monitoring`, sync wave -2
│           └── secret.enc.yaml     # Grafana admin mã hóa, sync wave -1
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

---

## Monitoring: Grafana và Prometheus trên OpenNebula dev

Cụm dev được tạo bằng OneKS trên hạ tầng của `one-deploy`, chạy RKE2
`v1.34.2+rke2r1`. Dùng kubeconfig `~/.kube/config-opennebula-dev`, context
`default`. Các node hiện tại là `172.20.0.16`, `172.20.0.17`, `172.20.0.18`.

Application `monitoring` dùng chart `kube-prometheus-stack` **90.0.0**, release
`monitoring`, namespace `monitoring`. ArgoCD kết hợp hai nguồn: Helm chart với
`$values/apps/monitoring/values.yaml`, và Git tại `apps/monitoring/base` qua CMP
`sops`. Namespace và Secret được áp dụng ở sync wave `-2` và `-1`; workload ở
wave mặc định. `ServerSideApply=true` hỗ trợ các CRD lớn của Prometheus Operator.

### Cấu hình dev

| Thành phần | Cấu hình |
| --- | --- |
| Grafana | 1 replica, NodePort `30300`, tài khoản `admin` |
| Prometheus | 1 replica, ClusterIP, retention `2d` / `2GiB` |
| Lưu trữ | `emptyDir` trên đĩa, không tạo PVC |
| Prometheus CPU / RAM | request `100m / 512Mi`, limit `1 / 2Gi` |
| Grafana CPU / RAM | request `100m / 128Mi`, limit `500m / 512Mi` |
| Metrics | API server, kubelet/cAdvisor, node-exporter, kube-state-metrics, CoreDNS |
| Dashboard | Dashboard Kubernetes có sẵn, datasource Prometheus mặc định |

Dữ liệu Prometheus và thay đổi Grafana lưu trong pod sẽ mất khi pod bị tạo lại.
Dashboard và datasource do chart quản lý được nạp lại tự động. Retention size
giới hạn dữ liệu TSDB; WAL và các file đang hoạt động có thể dùng thêm dung lượng.

Alertmanager chưa bật. Scrape etcd, scheduler, controller-manager, kube-proxy và
các rule liên quan tạm tắt cho đến khi xác minh endpoint metrics RKE2. Các alert
khác vẫn được đánh giá trong Prometheus nhưng chưa gửi thông báo ra ngoài.
Monitoring host OpenNebula do `one-deploy` quản lý không bị thay đổi.

### Đồng bộ qua GitOps

Sau khi commit và push các thay đổi lên nhánh mà root Application theo dõi,
ArgoCD tự tạo Application `monitoring` và đồng bộ. Không cài thêm release bằng
`helm install` vì các tài nguyên này được ArgoCD quản lý.

Các lệnh dưới đây dùng rõ kubeconfig dev để tránh thao tác nhầm context hiện tại:

```bash
# Khai báo hàm trong terminal đang sử dụng.
kdev() {
  kubectl --kubeconfig="$HOME/.kube/config-opennebula-dev" --context=default "$@"
}

kdev get nodes -o wide
kdev -n argocd get applications
kdev -n monitoring get pods,svc,pvc
```

Namespace `monitoring` không cần PVC. Nếu cần yêu cầu ArgoCD đọc lại Git ngay:

```bash
kdev -n argocd annotate application root-application argocd.argoproj.io/refresh=hard --overwrite
# Chạy sau khi Application monitoring đã xuất hiện.
kdev -n argocd annotate application monitoring argocd.argoproj.io/refresh=hard --overwrite
```

### Truy cập và kiểm tra

- Grafana: `http://172.20.0.17:30300` (hoặc IP một node khác), tài khoản `admin`.
- Máy truy cập phải có route tới mạng private `172.20.0.0/24` theo hướng dẫn
  `one-deploy/INSTALL-SNO.md`. NodePort dùng HTTP trong mạng dev, chưa cấu hình ingress/TLS.
- Mật khẩu ngẫu nhiên được quản lý trong Secret `grafana-admin`, mã hóa SOPS/Age
  trong Git. Lấy mật khẩu trên máy quản trị bằng lệnh sau, không đưa output vào Git:

```bash
kdev -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 --decode
```

Prometheus chỉ mở trong cluster; truy cập tạm thời qua:

```bash
kdev -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Mở `http://127.0.0.1:9090`, kiểm tra trang Targets và query `up`,
`count(kube_node_info)` (kỳ vọng `3`), `kube_pod_info{namespace="demo-nginx"}`.
Trong Grafana, mở dashboard **Kubernetes / Compute Resources / Cluster** và
**Kubernetes / Compute Resources / Namespace (Pods)** để kiểm tra dữ liệu node/pod.
Một số biểu đồ dùng cửa sổ rate cần vài phút sau lần scrape đầu tiên.

Nghiệm thu: Application `Synced/Healthy`, các pod Ready, Grafana đăng nhập được,
các target đã bật có trạng thái UP và dashboard có dữ liệu. Refresh lại Application
để xác nhận đồng bộ ổn định, không có thay đổi ngoài dự kiến.

### Kiểm tra trước khi nâng cấp

```bash
helm template monitoring kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --version 90.0.0 --namespace monitoring --kube-version 1.34.2 --include-crds \
  -f apps/monitoring/values.yaml > /tmp/opennebula-monitoring-rendered.yaml
git diff --check
```

Kiểm tra CRD, NodePort, Secret reference, datasource và không có PVC trong kết quả
render. Khi kiểm tra SOPS/Kustomize, giải mã trong thư mục tạm được bảo vệ rồi xóa
bản rõ sau kiểm tra; không giải mã tại chỗ trong working tree. Khi mã hóa Secret
mới từ stdin hoặc file chưa có đuôi `.enc.yaml`, dùng
`--filename-override apps/monitoring/base/secret.enc.yaml` để khớp `.sops.yaml`.
