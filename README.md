# SSKD K3s Infrastructure

## Для нового приложения нужно:

### 1. `deploy/values.yml`

```yaml
app:
  name: my-app
  ingress:
    enabled: true
    host: my-app.sskd.tech
```

### 2. `.github/workflows/deploy.yml`

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: username/repo/.github/workflows/deploy-app.yml@main
    with:
      app_name: my-app
      app_host: my-app.sskd.tech
    secrets: inherit
```

### 3. `Dockerfile`

---

## Настройка нового сервера

```bash
# K3s
curl -sfL https://get.k3s.io | sh -

# Kubectl config
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=120s
```

## ⚠️ Обязательно после установки — иначе через пару месяцев начнутся рестарты

На маленьких серверах (1-2GB RAM) control-plane нода легко забивается пользовательскими
приложениями и уходит в своп-трэшинг — coredns/traefik/metrics-server начинают ловить
ложные срабатывания проб и рестартоваться пачками. Разбор одного такого случая: coredns —
1000+ рестартов, нода на грани OOM. Три вещи ниже — не опциональны.

### 1. Тейнт control-plane ноды

Не пускать на неё ничего, кроме `kube-system`, `cert-manager`, `default` — остальные
namespace'ы (приложения) должны уезжать на другие ноды. Работает "из коробки" для будущих
деплоев и новых нод — ничего доплняно настраивать не надо, taint просто не пускает поды без
toleration.

```bash
kubectl taint nodes $(hostname) node-role.kubernetes.io/control-plane:NoSchedule
```

coredns/traefik/metrics-server уже умеют это toleration'ить сами (встроено в их манифесты).
headlamp и technitium-dnsserver — сторонние чарты, toleration для них уже прописан в
`charts/sskd-infrastructure/values.yaml`, ничего руками делать не нужно.

### 2. Таймауты проб для coredns и metrics-server

Дефолтный `timeoutSeconds: 1` слишком мал для нагруженной ноды — под первым же CPU/IO-стоппом
kubelet убивает coredns/metrics-server как ложное срабатывание.

При установке через `curl -sfL https://get.k3s.io | sh -` (как в шаге выше) coredns и
metrics-server ставятся как `Addon` (`k3s.cattle.io/v1`), обычные статические манифесты —
`HelmChartConfig` для них не работает, значения таймаутов правим прямо в манифестах на диске
ноды:
```bash
sudo grep -n "timeoutSeconds" /var/lib/rancher/k3s/server/manifests/coredns.yaml
sudo sed -i 's/timeoutSeconds: 1$/timeoutSeconds: 60/' /var/lib/rancher/k3s/server/manifests/coredns.yaml

# metrics-server — не файл, а папка с несколькими манифестами; нужный — *-deployment.yaml
# (имя может отличаться от версии к версии, проверьте sudo ls .../manifests/metrics-server/)
sudo grep -rn "timeoutSeconds" /var/lib/rancher/k3s/server/manifests/metrics-server/
sudo sed -i 's/timeoutSeconds: 1$/timeoutSeconds: 60/' /var/lib/rancher/k3s/server/manifests/metrics-server/metrics-server-deployment.yaml
```
k3s сам подхватит изменение файла и пересоздаст поды — рестарт сервиса не нужен.

⚠️ Это правка на диске конкретной ноды, вне git. После апгрейда k3s-бинаря стоит перепроверить
(`sudo grep -n timeoutSeconds ...`) — вдруг файл перезаписался дефолтом.

## 📊 Headlamp (Dashboard)

```bash
kubectl -n default create token sskd-infrastructure-headlamp
```

Открыть: `http://<SERVER_IP>:30080`

---

## DNS Server

Открыть: `http://<SERVER_IP>:30081`

## 📁 Структура

```
senior-script-kiddie-k3s/
├── charts/
│   ├── sskd-infrastructure/   # Namespace, SSL, Traefik, Headlamp
│   ├── sskd-library/          # Готовые шаблоны
│   └── sskd-app/              # Application chart
├── app-template/              # Шаблон для копирования
└── .github/workflows/
    ├── deploy-infrastructure.yml
    └── deploy-app.yml

my-app/
├── deploy/
│   └── values.yml
├── .github/workflows/
│   └── deploy.yml
└── Dockerfile
```
