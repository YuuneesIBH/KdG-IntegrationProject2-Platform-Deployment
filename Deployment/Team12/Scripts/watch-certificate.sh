#!/usr/bin/env bash
set -euo pipefail

# watch-certificate.sh
# Waits for a cert-manager Certificate to become Ready, then restarts a deployment to pick up the new TLS secret.

usage() {
  cat <<EOF
Usage: $0 [-n NAMESPACE] [-c CERT_NAME] [-d DEPLOYMENT] [--timeout SECONDS] [--interval SECONDS]

Options:
  -n, --namespace  Namespace (default: bordspelplatform-12)
  -c, --certificate Certificate name (default: stoom-app-cert)
  -d, --deployment Deployment to restart (default: nginx-gateway-deployment)
      --timeout   Max wait seconds (default: 5400 = 90m)
      --interval  Poll interval seconds (default: 15)
  -h, --help      Show help
EOF
}

NAMESPACE="bordspelplatform-12"
CERT_NAME="stoom-app-cert"
DEPLOYMENT="nginx-gateway-deployment"
TIMEOUT=5400
INTERVAL=15

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace) NAMESPACE="$2"; shift 2;;
    -c|--certificate) CERT_NAME="$2"; shift 2;;
    -d|--deployment) DEPLOYMENT="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    --interval) INTERVAL="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

echo "Watching certificate '$CERT_NAME' in namespace '$NAMESPACE' (timeout=${TIMEOUT}s, interval=${INTERVAL}s)..."

start_ts=$(date +%s)

get_ready_status() {
  kubectl get certificate "$CERT_NAME" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true
}

is_ready() {
  local status
  status=$(get_ready_status)
  [[ "$status" == "True" ]]
}

# Quick exit if already ready
if is_ready; then
  echo "Certificate is already Ready. Restarting deployment '$DEPLOYMENT' to pick up TLS..."
  kubectl rollout restart deployment/"$DEPLOYMENT" -n "$NAMESPACE" || true
  exit 0
fi

# Poll until ready or timeout
while true; do
  if is_ready; then
    echo "Certificate became Ready. Restarting deployment '$DEPLOYMENT'..."
    kubectl rollout restart deployment/"$DEPLOYMENT" -n "$NAMESPACE" || true
    echo "Done."
    exit 0
  fi
  now=$(date +%s)
  elapsed=$(( now - start_ts ))
  if (( elapsed >= TIMEOUT )); then
    echo "Timeout (${TIMEOUT}s) waiting for certificate '$CERT_NAME' to become Ready. Exiting without restart."
    exit 2
  fi
  sleep "$INTERVAL"
 done
