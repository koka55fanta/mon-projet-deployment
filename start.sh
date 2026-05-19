#!/bin/bash
# Déterminer le répertoire du script
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"
echo "=========================================="
echo "🚀 Démarrage complet du projet DevOps"
echo "=========================================="
# ── 1. Création du cluster k3d ──
if k3d cluster list 2>/dev/null | grep -q "mon-cluster"; then
  echo "✅ Le cluster 'mon-cluster' existe déjà."
else
  echo "🔧 Création du cluster k3d..."
  k3d cluster create --config k3d-config.yaml
  if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de la création du cluster. Tentative sans fichier config..."
    k3d cluster create mon-cluster --servers 1 --agents 2 -p "8080:80@loadbalancer"
  fi
  echo "✅ Cluster k3d créé !"
fi
# Vérifier que kubectl fonctionne
echo "⏳ Vérification de la connexion au cluster..."
kubectl cluster-info
if [ $? -ne 0 ]; then
  echo "❌ kubectl ne peut pas se connecter au cluster !"
  echo "Essayons de configurer kubeconfig..."
  k3d kubeconfig merge mon-cluster --kubeconfig-switch-context
fi
# Attendre que les nodes soient prêts
echo "⏳ Attente que les nodes soient prêts..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s || echo "⚠️ Timeout sur les nodes, on continue quand même..."
# ── 2. Installation d'ArgoCD ──
echo "🚀 Installation d'ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "⏳ Attente qu'ArgoCD démarre (cela peut prendre 2-3 minutes)..."
kubectl -n argocd rollout status deployment argocd-server --timeout=300s || echo "⚠️ ArgoCD met du temps, on continue le déploiement..."
# Patcher ArgoCD pour désactiver HTTPS (Codespaces gère déjà le HTTPS)
echo "🔧 Configuration d'ArgoCD en mode HTTP (compatible Codespaces)..."
kubectl -n argocd patch deployment argocd-server --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}
]' 2>/dev/null || echo "⚠️ Patch insecure déjà appliqué"
kubectl -n argocd rollout status deployment argocd-server --timeout=120s || true
# ── 3. Déploiement DIRECT des ressources Kubernetes ──
echo ""
echo "📦 Déploiement de MySQL et de l'Application Web..."
echo "---"
echo "  → mysql-configmap.yaml"
kubectl apply -f k8s-projet/mysql-configmap.yaml
echo "  → mysql-deployment.yaml"
kubectl apply -f k8s-projet/mysql-deployment.yaml
echo "  → web-deployment.yaml"
kubectl apply -f k8s-projet/web-deployment.yaml
echo "  → network-policy.yaml"
kubectl apply -f k8s-projet/network-policy.yaml
echo "  → ingress.yaml"
kubectl apply -f k8s-projet/ingress.yaml
echo ""
echo "⏳ Attente de 15 secondes pour que Kubernetes crée les pods..."
sleep 15
# ── 4. Vérification des pods ──
echo ""
echo "=========================================="
echo "📋 État des pods dans le namespace 'default' :"
echo "=========================================="
kubectl get pods -o wide
echo ""
echo "📋 État de TOUS les pods du cluster :"
kubectl get pods -A
echo ""
# ── 5. Déploiement des applications ArgoCD (optionnel) ──
echo "🔄 Configuration des applications ArgoCD..."
kubectl apply -f argocd/argocd-app.yaml 2>/dev/null || echo "⚠️ argocd-app.yaml non appliqué (ArgoCD pas encore prêt)"
kubectl apply -f argocd/monitoring-application.yaml 2>/dev/null || echo "⚠️ monitoring-application.yaml non appliqué"
# ── 6. Récupération du mot de passe ArgoCD ──
echo ""
echo "=========================================="
echo "✅ Déploiement terminé !"
echo "=========================================="
echo ""
echo "📋 Mot de passe ArgoCD (user: admin) :"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo "" || echo "  (pas encore disponible, attendez 1-2 minutes)"
echo ""
echo "🌐 Pour accéder aux services, lancez : bash tunnels.sh"
echo "  - Application Web : port 8081"
echo "  - Grafana         : port 8082"
echo "  - ArgoCD          : port 8085"
echo ""
echo "💡 Si les pods sont en 'ContainerCreating', attendez 1 minute puis tapez :"
echo "   kubectl get pods"
