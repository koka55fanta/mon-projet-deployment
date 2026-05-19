#!/bin/bash

echo "🛠️ Vérification de Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "📈 Installation de Prometheus & Grafana avec les limites de RAM..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    -f k8s-projet/boost-ram.yaml

echo "✅ Monitoring installé et optimisé en RAM !"