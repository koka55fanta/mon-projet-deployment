#!/bin/bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "🚀 Installation d'ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "📦 Déploiement de MySQL et de l'Application Web..."
kubectl apply -f k8s-projet/config-mysql.yaml
kubectl apply -f k8s-projet/web-deployment.yaml

echo "✅ Les bases sont en place !"
