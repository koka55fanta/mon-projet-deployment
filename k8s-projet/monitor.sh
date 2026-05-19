#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "🛠️ Vérification de Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "📈 Installation de Prometheus & Grafana avec les limites de RAM..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

helm upgrade --install kube-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    --set prometheus.prometheusSpec.resources.requests.memory="512Mi" \
    --set prometheus.prometheusSpec.resources.limits.memory="2Gi" \
    --set grafana.resources.requests.memory="128Mi" \
    --set grafana.resources.limits.memory="512Mi" \
    --set alertmanager.alertmanagerSpec.resources.requests.memory="64Mi" \
    --set alertmanager.alertmanagerSpec.resources.limits.memory="256Mi"

echo "✅ Monitoring installé et optimisé en RAM !"