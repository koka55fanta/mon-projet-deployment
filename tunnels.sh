#!/bin/bash
echo "🔄 1. Attente du réveil de Kubernetes (K3s)..."
until kubectl get nodes > /dev/null 2>&1; do sleep 2; done

echo "🚀 2. Réveil de l'infrastructure..."
kubectl scale deployment argocd-server argocd-repo-server argocd-dex-server argocd-notifications-controller -n argocd --replicas=1
kubectl scale statefulset argocd-application-controller -n argocd --replicas=1
kubectl scale deployment kube-stack-kube-prometheus-operator kube-stack-grafana -n monitoring --replicas=1
kubectl scale statefulset prometheus-kube-stack-kube-prometheus-prometheus alertmanager-kube-stack-kube-prometheus-alertmanager -n monitoring --replicas=1

echo "⏳ 3. Attente de la disponibilité des outils DevOps..."
# On attend ArgoCD
kubectl wait --for=condition=available --timeout=120s deployment/argocd-server -n argocd
# 🚀 NOUVEAU : On attend Grafana
kubectl wait --for=condition=available --timeout=120s deployment/kube-stack-grafana -n monitoring

echo "🌍 4. Attente de l'application Web et MySQL (Patience...)"
kubectl wait --for=condition=available --timeout=180s deployment/web

echo "🌐 5. Lancement sécurisé des tunnels..."
pkill -f "port-forward"
sleep 2

# Lancement en arrière-plan
kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /dev/null 2>&1 &
kubectl port-forward svc/argocd-server -n argocd 8085:80 --address 0.0.0.0 > /dev/null 2>&1 &
kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /dev/null 2>&1 &

echo "✅ TOUT EST PRÊT ! Les interfaces sont opérationnelles."
