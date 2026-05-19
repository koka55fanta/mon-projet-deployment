#!/bin/bash
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"
echo "🌐 Lancement automatique des tunnels..."
# On ferme les anciens tunnels au cas où
pkill -f "port-forward" 2>/dev/null || true
sleep 2
# Fonction pour attendre qu'un service existe
wait_for_service() {
  local svc=$1
  local ns=$2
  local max_wait=120
  local waited=0
  echo "⏳ Attente du service $svc (namespace: $ns)..."
  while ! kubectl get svc "$svc" -n "$ns" &>/dev/null; do
    sleep 5
    waited=$((waited + 5))
    if [ $waited -ge $max_wait ]; then
      echo "⚠️  Timeout: le service $svc n'est pas disponible après ${max_wait}s"
      return 1
    fi
  done
  echo "✅ Service $svc trouvé !"
  return 0
}
# On ouvre les accès
echo "🔗 Ouverture du port 8081 (Application Web)..."
if wait_for_service "web-service" "default"; then
  kubectl port-forward svc/web-service 8081:80 --address 0.0.0.0 > /dev/null 2>&1 &
fi
echo "🔗 Ouverture du port 8085 (ArgoCD)..."
if wait_for_service "argocd-server" "argocd"; then
  kubectl port-forward svc/argocd-server -n argocd 8085:8080 --address 0.0.0.0 > /dev/null 2>&1 &
fi
echo "🔗 Ouverture du port 8082 (Grafana)..."
if wait_for_service "kube-stack-grafana" "monitoring"; then
  kubectl port-forward svc/kube-stack-grafana -n monitoring 8082:80 --address 0.0.0.0 > /dev/null 2>&1 &
else
  echo "⚠️  Grafana n'est pas encore déployé. Relancez 'bash tunnels.sh' après le déploiement du monitoring."
fi
echo ""
echo "✅ Tunnels activés avec succès !"
echo "  - Application Web : http://localhost:8081"
echo "  - ArgoCD          : http://localhost:8085"
echo "  - Grafana         : http://localhost:8082"
