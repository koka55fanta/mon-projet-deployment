#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "=========================================="
echo "🚀 Démarrage complet du projet DevOps"
echo "=========================================="

# ── 1. Création du cluster k3d ──
if k3d cluster list | grep -q "mon-cluster"; then
  echo "✅ Le cluster 'mon-cluster' existe déjà."
else
  echo "🔧 Création du cluster k3d..."
  k3d cluster create --config k3d-config.yaml
  echo "✅ Cluster k3d créé !"
fi

# Attendre que les nodes soient prêts
echo "⏳ Attente que les nodes soient prêts..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# ── 2. Installation d'ArgoCD ──
echo "🚀 Installation d'ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Attente qu'ArgoCD soit prêt..."
kubectl -n argocd rollout status deployment argocd-server --timeout=180s

# ── 3. Déploiement des ressources Kubernetes ──
echo "📦 Déploiement de MySQL et de l'Application Web..."
kubectl apply -f k8s-projet/mysql-configmap.yaml
kubectl apply -f k8s-projet/mysql-deployment.yaml
kubectl apply -f k8s-projet/web-deployment.yaml
kubectl apply -f k8s-projet/network-policy.yaml
kubectl apply -f k8s-projet/ingress.yaml

# ── 4. Déploiement des applications ArgoCD ──
echo "🔄 Configuration des applications ArgoCD..."
kubectl apply -f argocd/argocd-app.yaml
kubectl apply -f argocd/monitoring-application.yaml

# ── 5. Récupération du mot de passe ArgoCD ──
echo ""
echo "=========================================="
echo "✅ Déploiement terminé avec succès !"
echo "=========================================="
echo ""
echo "📋 Mot de passe ArgoCD (user: admin) :"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo "" || echo "  (pas encore disponible, relancez cette commande plus tard)"
echo ""
echo "🌐 Pour accéder aux services, lancez : bash tunnels.sh"
echo "  - Application Web : port 8081"
echo "  - Grafana         : port 8082"
echo "  - ArgoCD          : port 8085"
