#!/bin/bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
LOG_FILE="/tmp/tunnels-startup.log"
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "--- Début de tunnels.sh à $(date) ---"
echo "🔄 0. Attente du réveil de K3s..."
until kubectl get nodes > /dev/null 2>&1; do sleep 3; done
echo "🚀 K3s est prêt !"

# Sécurité : On allume ArgoCD et Monitoring SEULEMENT s'ils sont installés
if kubectl get namespace argocd > /dev/null 2>&1; then
    echo "🚀 1. Réveil d'ArgoCD..."
    kubectl scale deployment argocd-server argocd-repo-server argocd-dex-server argocd-notifications-controller -n argocd --replicas=1 2>/dev/null || true
    kubectl scale statefulset argocd-application-controller -n argocd --replicas=1 2>/dev/null || true
fi

if kubectl get namespace monitoring > /dev/null 2>&1; then
    echo "📈 2. Réveil du Monitoring..."
    kubectl scale deployment kube-stack-kube-prometheus-operator kube-stack-grafana -n monitoring --replicas=1 2>/dev/null || true
    kubectl scale statefulset prometheus-kube-stack-kube-prometheus-prometheus alertmanager-kube-stack-kube-prometheus-alertmanager -n monitoring --replicas=1 2>/dev/null || true
fi

echo "⏳ Attente de 15 secondes pour laisser les pods démarrer..."
sleep 15

echo "🧹 3. Nettoyage des anciens tunnels..."
pkill -f "port-forward"
sleep 2

echo "🌐 4. Lancement des tunnels..."
# On ouvre les tunnels uniquement si les services existent
if kubectl get svc web-service > /dev/null 2>&1; then
    nohup kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /tmp/port-forward-web.log 2>&1 &
fi
if kubectl get svc argocd-server -n argocd > /dev/null 2>&1; then
    nohup kubectl port-forward svc/argocd-server -n argocd 8085:80 --address 0.0.0.0 > /tmp/port-forward-argo.log 2>&1 &
fi
if kubectl get svc kube-stack-grafana -n monitoring > /dev/null 2>&1; then
    nohup kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /tmp/port-forward-grafana.log 2>&1 &
fi
echo "✅ Script terminé avec succès !"
