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

## 📊 Headlamp (Dashboard)

```bash
kubectl -n kube-system create token headlamp-admin
```

Открыть: `http://<SERVER_IP>:30080`

---

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
