#!/usr/bin/env bash
# E2E test of the Gateway API path (HTTPRoute + BackendTLSPolicy) using Envoy Gateway.
set -o errexit
set -o pipefail
set -o nounset

cd "$(dirname "${BASH_SOURCE[0]}")"

CLUSTER_NAME="globaleaks-e2e-envoy"
CHART_DIR="./globaleaks"
HOST="globaleaks.example.com"
RELEASE="globaleaks1"
KEEP_CLUSTER="${KEEP_CLUSTER:-false}"
WORKDIR="$(mktemp -d)"
PF_PID=""

cleanup() {
  [[ -n "$PF_PID" ]] && kill "$PF_PID" 2>/dev/null || true
  rm -rf "$WORKDIR"
  if [[ "$KEEP_CLUSTER" != "true" ]]; then
    echo "==> deleting kind cluster $CLUSTER_NAME"
    kind delete cluster --name "$CLUSTER_NAME" || true
  else
    echo "==> KEEP_CLUSTER=true, leaving cluster $CLUSTER_NAME up"
  fi
}
trap cleanup EXIT

resolved="$(getent hosts "$HOST" | awk '{print $1}' || true)"
if [[ "$resolved" != "127.0.0.1" ]]; then
  echo "ERROR: $HOST does not resolve to 127.0.0.1 (add it to /etc/hosts first)" >&2
  exit 1
fi

echo "==> creating kind cluster $CLUSTER_NAME"
kind create cluster --name "$CLUSTER_NAME" --config kind-envoy.yml

echo "==> installing Envoy Gateway"
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --namespace envoy-gateway-system --create-namespace --wait --timeout 5m

echo "==> creating Gateway"
openssl req -x509 -newkey rsa:2048 -nodes -keyout "$WORKDIR/k.pem" -out "$WORKDIR/c.pem" \
  -days 2 -subj "/CN=$HOST" -addext "subjectAltName=DNS:$HOST" 2>/dev/null
kubectl create secret tls gw-tls --cert="$WORKDIR/c.pem" --key="$WORKDIR/k.pem"
kubectl apply -f envoy-gateway.yml
kubectl wait gateway/eg --for=condition=Programmed --timeout=180s

echo "==> installing release '$RELEASE' (no ingress, no route yet)"
helm install "$RELEASE" "$CHART_DIR" \
  --set ingress.enabled=false --set ingress.host="$HOST" --set global.tenant=bcn \
  --wait --timeout 5m

echo "==> fetching the backend's self-signed certificate to use as CA"
kubectl port-forward "$RELEASE-globaleaks-0" 18444:8443 >/dev/null 2>&1 &
PF_PID=$!
for ((i = 1; i <= 15; i++)); do
  if echo | openssl s_client -connect 127.0.0.1:18444 2>/dev/null | openssl x509 > "$WORKDIR/be.pem" 2>/dev/null \
     && [[ -s "$WORKDIR/be.pem" ]]; then
    break
  fi
  sleep 1
done
[[ -s "$WORKDIR/be.pem" ]] || { echo "ERROR: could not fetch backend certificate" >&2; exit 1; }
kill "$PF_PID" 2>/dev/null || true
PF_PID=""
kubectl create configmap globaleaks-ca --from-file=ca.crt="$WORKDIR/be.pem"

echo "==> enabling httpRoute"
cat > "$WORKDIR/values.yaml" <<VALUES
ingress: {enabled: false, host: $HOST}
global: {tenant: bcn}
httpRoute:
  enabled: true
  parentRefs: [{name: eg, sectionName: https}]
  redirect: {enabled: true, parentRefs: [{name: eg, sectionName: http}]}
  backendTLS:
    # GlobaLeaks' self-signed certificate is issued for 127.0.0.1
    hostname: 127.0.0.1
    caCertificateRefs: [{group: "", kind: ConfigMap, name: globaleaks-ca}]
VALUES
helm upgrade "$RELEASE" "$CHART_DIR" -f "$WORKDIR/values.yaml" --wait --timeout 5m

echo "==> checking route and policy status"
kubectl wait httproute/"$RELEASE-globaleaks" --for=jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}'=True --timeout=60s
kubectl wait httproute/"$RELEASE-globaleaks" --for=jsonpath='{.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status}'=True --timeout=60s
kubectl wait backendtlspolicy/"$RELEASE-globaleaks" \
  --for=jsonpath='{.status.ancestors[0].conditions[?(@.type=="Accepted")].status}'=True --timeout=60s

# The gateway reconfigures Envoy asynchronously: retry until the expected status shows up.
check_http() {
  local url="$1" pattern="$2" retries=30 delay=2 code
  echo "==> checking $url (expecting $pattern)"
  for ((i = 1; i <= retries; i++)); do
    code="$(curl -k -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" || true)"
    if [[ "$code" =~ $pattern ]]; then
      echo "OK: $url returned HTTP $code (attempt $i/$retries)"
      return 0
    fi
    sleep "$delay"
  done
  echo "ERROR: $url still returning HTTP $code after $((retries * delay))s" >&2
  return 1
}

check_http "https://$HOST:18443/" '^2[0-9][0-9]$'
check_http "http://$HOST:18080/" '^301$'

echo "==> killing the container from the node to check restart with a stale pidfile"
docker exec "${CLUSTER_NAME}-control-plane" sh -c \
  "crictl stop --timeout 0 \$(crictl ps -q --name $RELEASE-globaleaks)"
sleep 5
kubectl wait --for=condition=Ready pod/"$RELEASE-globaleaks-0" --timeout=180s
restarts="$(kubectl get pod "$RELEASE-globaleaks-0" -o jsonpath='{.status.containerStatuses[0].restartCount}')"
if [[ "$restarts" -lt 1 ]]; then
  echo "ERROR: expected the container to have restarted (restartCount=$restarts)" >&2
  exit 1
fi
check_http "https://$HOST:18443/" '^2[0-9][0-9]$'

echo "==> all checks passed"
