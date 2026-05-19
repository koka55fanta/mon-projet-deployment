# 🚀 Mon Projet Deployment - DevOps Kubernetes

Projet DevOps complet déployant une application web PHP + MySQL sur un cluster Kubernetes (k3d) avec GitOps (ArgoCD) et monitoring (Prometheus/Grafana), optimisé pour GitHub Codespaces 16GB RAM.

## 📋 Architecture

```
├── .devcontainer/          # Configuration GitHub Codespaces (16GB RAM)
│   └── devcontainer.json
├── argocd/                 # Manifestes ArgoCD (hors du scope de sync)
│   ├── argocd-app.yaml           # Application ArgoCD pour le déploiement GitOps
│   └── monitoring-application.yaml # Stack monitoring via Helm
├── k8s-projet/             # Manifestes Kubernetes (source ArgoCD)
│   ├── mysql-configmap.yaml      # Script SQL d'initialisation de la BDD
│   ├── mysql-deployment.yaml     # Deployment + PVC + Service MySQL
│   ├── web-deployment.yaml       # Deployment + Service de l'app web
│   ├── network-policy.yaml       # Sécurité réseau (seul web → MySQL)
│   ├── ingress.yaml              # Ingress Traefik
│   ├── bd.sql                    # Script SQL standalone
│   └── monitor.sh                # Installation manuelle du monitoring
├── k3d-config.yaml         # Configuration du cluster k3d
├── start.sh                # Script de démarrage complet
└── tunnels.sh              # Ouverture des tunnels port-forward
```

## 🚀 Démarrage rapide (Codespace)

1. **Créer un Codespace** depuis ce repo (choisir la machine 16GB RAM / 4 CPU)
2. Le cluster se lance automatiquement via `postStartCommand`
3. Lancer les tunnels : `bash tunnels.sh`

## 🔗 Accès aux services

| Service | Port | URL |
|---------|------|-----|
| Application Web | 8081 | http://localhost:8081 |
| Grafana | 8082 | http://localhost:8082 |
| ArgoCD | 8085 | http://localhost:8085 |

## 🔑 Identifiants

### ArgoCD
- **User** : `admin`
- **Mot de passe** : `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### MySQL
- **Root** : `tK5aE!aE(_FU4_dv`
- **App user** : `appuser` / `apppassword`
- **Base** : `bd_final`

### Grafana
- **User** : `admin`
- **Mot de passe** : `prom-operator`

## 🛠️ Scripts disponibles

```bash
bash start.sh      # Démarrage complet (cluster + ArgoCD + apps)
bash tunnels.sh    # Ouverture des tunnels port-forward
bash k8s-projet/monitor.sh  # Installation manuelle du monitoring via Helm
```

## 📊 Limites de ressources (optimisé 16GB)

| Composant | RAM Request | RAM Limit |
|-----------|------------|-----------|
| MySQL | 256Mi | 1Gi |
| Web App (×2) | 64Mi | 256Mi |
| Prometheus | 512Mi | 2Gi |
| Grafana | 128Mi | 512Mi |
| Alertmanager | 64Mi | 256Mi |
