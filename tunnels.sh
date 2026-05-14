#!/bin/bash
echo "🔄 1. Attente du réveil de Kubernetes (K3s)..."
# Cette boucle tourne dans le vide tant que l'API de K3s ne répond pas
until kubectl get nodes > /dev/null 2>&1; do sleep 2; done

echo "🚀 2. Réveil de l'infrastructure (ArgoCD & Monitoring)..."
kubectl scale deployment argocd-server argocd-repo-server argocd-dex-server argocd-notifications-controller -n argocd --replicas=1
kubectl scale statefulset argocd-application-controller -n argocd --replicas=1
kubectl scale deployment kube-stack-kube-prometheus-operator kube-stack-grafana -n monitoring --replicas=1
kubectl scale statefulset prometheus-kube-stack-kube-prometheus-prometheus alertmanager-kube-stack-kube-prometheus-alertmanager -n monitoring --replicas=1

echo "⏳ 3. Attente du démarrage complet (Patience, environ 1 à 2 minutes)..."
# On force le script à bloquer ici tant qu'ArgoCD n'est pas prêt à 100%
kubectl wait --for=condition=available --timeout=120s deployment/argocd-server -n argocd

echo "🌐 4. Lancement sécurisé des tunnels..."
pkill -f "port-forward"
sleep 2

# Lancement en arrière-plan
kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /dev/null 2>&1 &
kubectl port-forward svc/argocd-server -n argocd 8085:80 --address 0.0.0.0 > /dev/null 2>&1 &
kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /dev/null 2>&1 &

echo "✅ TOUT EST PRÊT ! Les interfaces sont opérationnelles."
