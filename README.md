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
    uses: alkhipce/senior-script-kiddie-k3s/.github/workflows/deploy-app.yml@main
    with:
      app_name: my-app
      app_host: my-app.sskd.tech
    secrets: inherit
```

### 3. `Dockerfile`

---

## Поднятие инфраструктуры:

### Установка инфраструктуры

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
