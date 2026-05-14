#!/bin/bash
echo "🌐 Lancement automatique des tunnels K3s..."
pkill -f "port-forward"
sleep 2
kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /dev/null 2>&1 &
kubectl port-forward svc/argocd-server -n argocd 8085:80 --address 0.0.0.0 > /dev/null 2>&1 &
kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /dev/null 2>&1 &
echo "✅ Tunnels activés !"
