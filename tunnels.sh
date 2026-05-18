#!/bin/bash

# Fichier de log pour voir ce qui se passe
LOG_FILE="/tmp/tunnels-startup.log"
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "--- Début du script tunnels.sh à $(date) ---"

echo "🔄 0. Attente du réveil de Kubernetes (K3s)..."
until kubectl get nodes > /dev/null 2>&1; do sleep 2; done
echo "K3s est réveillé !"

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

echo "🌐 5. Lancement des tunnels avec NOHUP..."
nohup kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /tmp/port-forward-web.log 2>&1 &
nohup kubectl port-forward svc/argocd-server -n argocd 8085:80 --address 0.0.0.0 > /tmp/port-forward-argo.log 2>&1 &
nohup kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /tmp/port-forward-grafana.log 2>&1 &

echo "✅ Script terminé à $(date)"
