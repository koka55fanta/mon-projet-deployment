#!/bin/bash
echo "🔄 0. Attente du réveil de Kubernetes (K3s)..."
until kubectl get nodes > /dev/null 2>&1; do sleep 2; done

echo "🚀 1. Allumage d'ArgoCD..."
kubectl scale deployment argocd-server argocd-repo-server argocd-dex-server argocd-notifications-controller -n argocd --replicas=1
kubectl scale statefulset argocd-application-controller -n argocd --replicas=1

echo "⏳ Attente de 15 secondes pour laisser le CPU respirer..."
sleep 15

echo "📈 2. Allumage de la stack Monitoring (Prometheus & Grafana)..."
kubectl scale deployment kube-stack-kube-prometheus-operator kube-stack-grafana -n monitoring --replicas=1
kubectl scale statefulset prometheus-kube-stack-kube-prometheus-prometheus alertmanager-kube-stack-kube-prometheus-alertmanager -n monitoring --replicas=1

echo "⏳ 3. Attente supplémentaire de 30 secondes pour MySQL et l'app Web..."
sleep 30

echo "🧹 4. Nettoyage des réseaux..."
pkill -f "port-forward"
sleep 2

echo "🌐 5. Lancement des tunnels avec NOHUP (Anti-crash)..."
# 🚀 AJOUT DE NOHUP POUR RENDRE LES TUNNELS IMMORTELS
nohup kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /dev/null 2>&1 &
nohup kubectl port-forward svc/argocd-server -n argocd 8085:80 --address 0.0.0.0 > /dev/null 2>&1 &
nohup kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /dev/null 2>&1 &

echo "✅ TOUT EST EN LIGNE !"
