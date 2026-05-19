#!/bin/bash

echo "🚀 Installation d'ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "📦 Déploiement de MySQL et de l'Application Web..."
# On applique le ConfigMap en premier pour que la BDD puisse s'initialiser
kubectl apply -f k8s-projet/mysql-configmap.yaml
kubectl apply -f k8s-projet/mysql-deployment.yaml

# On déploie ensuite ton application web
kubectl apply -f k8s-projet/web-deployment.yaml

echo "✅ Les bases sont en place !"