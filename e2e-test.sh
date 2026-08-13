#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

cd "$(dirname "${BASH_SOURCE[0]}")"

CLUSTER_NAME="globaleaks-e2e"
CHART_DIR="./globaleaks"
KEEP_CLUSTER="${KEEP_CLUSTER:-false}"

cleanup() {
  if [[ "$KEEP_CLUSTER" != "true" ]]; then
    echo "==> deleting kind cluster $CLUSTER_NAME"
    kind delete cluster --name "$CLUSTER_NAME" || true
  else
    echo "==> KEEP_CLUSTER=true, leaving cluster $CLUSTER_NAME up"
  fi
}
trap cleanup EXIT

for host in azienda1.example.com globaleaks.example.com; do
  resolved="$(getent hosts "$host" | awk '{print $1}' || true)"
  if [[ "$resolved" != "127.0.0.1" ]]; then
    echo "ERROR: $host does not resolve to 127.0.0.1 (add it to /etc/hosts first)" >&2
    exit 1
  fi
done

echo "==> creating kind cluster $CLUSTER_NAME"
kind create cluster --name "$CLUSTER_NAME" --config kind.yml

echo "==> installing ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.admissionWebhooks.enabled=false \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=NodePort \
  --wait --timeout 5m

echo "==> applying IngressClass"
kubectl apply -f ingressClass.yml

install_tenant() {
  local release="$1" host="$2" tenant="$3"
  echo "==> installing release '$release' for $host (tenant=$tenant)"
  helm install "$release" -f "$CHART_DIR/values.yaml" "$CHART_DIR" \
    --set ingress.host="$host" \
    --set global.tenant="$tenant" \
    --wait --timeout 5m
}

install_tenant globaleaks1 globaleaks.example.com bcn
install_tenant azienda1 azienda1.example.com azienda1

echo "==> checking PVCs are Bound"
kubectl get pvc
for pvc in globaleaks1-pvc azienda1-pvc; do
  phase="$(kubectl get pvc "$pvc" -o jsonpath='{.status.phase}')"
  if [[ "$phase" != "Bound" ]]; then
    echo "ERROR: PVC $pvc is not Bound (phase=$phase)" >&2
    exit 1
  fi
done

check_host() {
  # ingress-nginx picks up new/changed Ingress objects asynchronously, so right
  # after `helm install` returns (pod Ready) the controller may not have
  # reloaded its config for that host yet - retry for a bit before failing.
  local host="$1" retries=30 delay=2 code
  echo "==> checking https://$host:18443/"
  for ((i = 1; i <= retries; i++)); do
    code="$(curl -k -s -o /dev/null -w '%{http_code}' --max-time 5 "https://$host:18443/" || true)"
    if [[ "$code" =~ ^(2|3)[0-9][0-9]$ ]]; then
      echo "OK: $host returned HTTP $code (attempt $i/$retries)"
      return 0
    fi
    sleep "$delay"
  done
  echo "ERROR: $host still returning HTTP $code after $((retries * delay))s" >&2
  return 1
}

check_host globaleaks.example.com
check_host azienda1.example.com

echo "==> all checks passed"
