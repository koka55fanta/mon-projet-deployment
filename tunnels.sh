#!/bin/bash

echo "🌐 Lancement automatique des tunnels..."

# On ferme les anciens tunnels au cas où
pkill -f "port-forward"
sleep 2

# On ouvre les nouveaux accès
echo "🔗 Ouverture du port 8081 (Application Web)..."
kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /dev/null 2>&1 &
echo "🔗 Ouverture du port 8085 (ArgoCD)..."
kubectl port-forward svc/argocd-server -n argocd 8085:80 --address 0.0.0.0 > /dev/null 2>&1 &

echo "🔗 Ouverture du port 8082 (Grafana)..."
kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /dev/null 2>&1 &

echo "✅ Tunnels activés avec succès !"