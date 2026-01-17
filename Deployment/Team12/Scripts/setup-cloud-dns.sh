#!/usr/bin/env bash
set -euo pipefail

# setup-cloud-dns.sh
# Upsert A records for a domain (root and www) in Google Cloud DNS.
# Defaults for this repo: zone autodetected, domain stoom-app.com,
# service nginx-gateway-service in namespace bordspelplatform-12.

usage() {
  cat <<EOF
Usage: $0 [-z ZONE_NAME] [-d DOMAIN] [-n NAMESPACE] [-s SERVICE] [--ttl TTL] [--ip EXTERNAL_IP]

Options:
  -z, --zone        Cloud DNS managed zone name (autodetects by domain if omitted)
  -d, --domain      Domain name (default: stoom-app.com)
  -n, --namespace   Kubernetes namespace for service (default: bordspelplatform-12)
  -s, --service     Kubernetes service name to read external IP from (default: nginx-gateway-service)
      --ttl         TTL seconds for A records (default: 300)
      --ip          Override IP (skip k8s service lookup)
  -h, --help        Show this help

Examples:
  $0 --domain stoom-app.com
  $0 --zone my-zone --domain stoom-app.com --ip 203.0.113.10
EOF
}

ZONE_NAME=""
DOMAIN="stoom-app.com"
NAMESPACE="bordspelplatform-12"
SERVICE_NAME="nginx-gateway-service"
TTL="60"
OVERRIDE_IP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -z|--zone) ZONE_NAME="$2"; shift 2;;
    -d|--domain) DOMAIN="$2"; shift 2;;
    -n|--namespace) NAMESPACE="$2"; shift 2;;
    -s|--service) SERVICE_NAME="$2"; shift 2;;
    --ttl) TTL="$2"; shift 2;;
    --ip) OVERRIDE_IP="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

# Requirements checks
command -v gcloud >/dev/null || { echo "gcloud not found. Install Google Cloud SDK."; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl not found."; exit 1; }

echo "Domain: ${DOMAIN}"
echo "Namespace/Service: ${NAMESPACE}/${SERVICE_NAME}"

# Resolve zone if not provided
if [[ -z "${ZONE_NAME}" ]]; then
  ZONE_NAME=$(gcloud dns managed-zones list \
    --filter="dnsName=${DOMAIN}." \
    --format="value(name)" | head -n1 || true)
fi

# If still empty, create a new zone with a derived name
if [[ -z "${ZONE_NAME}" ]]; then
  DERIVED_ZONE="${DOMAIN//./-}"
  echo "No zone found for ${DOMAIN}. Creating managed zone '${DERIVED_ZONE}'..."
  gcloud dns managed-zones create "${DERIVED_ZONE}" \
    --dns-name="${DOMAIN}." \
    --description="Managed by setup-cloud-dns.sh for ${DOMAIN}" >/dev/null
  ZONE_NAME="${DERIVED_ZONE}"
fi

echo "Using managed zone: ${ZONE_NAME}"

# Determine IP
EXTERNAL_IP="${OVERRIDE_IP}"
if [[ -z "${EXTERNAL_IP}" ]]; then
  EXTERNAL_IP=$(kubectl get svc "${SERVICE_NAME}" -n "${NAMESPACE}" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
fi

if [[ -z "${EXTERNAL_IP}" ]]; then
  echo "ERROR: Could not determine external IP for service ${NAMESPACE}/${SERVICE_NAME}."
  echo "You can pass an explicit IP via --ip <IP>."
  exit 1
fi

echo "Target IP: ${EXTERNAL_IP}"

# Helper to upsert A record
upsert_a() {
  local name="$1"   # e.g. stoom-app.com. or www.stoom-app.com.
  local ip="$2"

  CURRENT=$(gcloud dns record-sets list --zone="${ZONE_NAME}" \
    --name="${name}" --type=A --format="value(rrdatas[0])" || true)

  if [[ "${CURRENT}" == "${ip}" ]]; then
    echo "A ${name} already points to ${ip} (no change)."
    return 0
  fi

  echo "Upserting A ${name} → ${ip} (TTL ${TTL})"
  TMPDIR=$(mktemp -d)
  pushd "${TMPDIR}" >/dev/null
  gcloud dns record-sets transaction start --zone="${ZONE_NAME}" >/dev/null
  if [[ -n "${CURRENT}" ]]; then
    gcloud dns record-sets transaction remove "${CURRENT}" \
      --name="${name}" --ttl="${TTL}" --type=A --zone="${ZONE_NAME}" >/dev/null || true
  fi
  gcloud dns record-sets transaction add "${ip}" \
    --name="${name}" --ttl="${TTL}" --type=A --zone="${ZONE_NAME}" >/dev/null
  gcloud dns record-sets transaction execute --zone="${ZONE_NAME}" >/dev/null
  popd >/dev/null
  rm -rf "${TMPDIR}"
}

ROOT_NAME="${DOMAIN}."
WWW_NAME="www.${DOMAIN}."

upsert_a "${ROOT_NAME}" "${EXTERNAL_IP}"
upsert_a "${WWW_NAME}" "${EXTERNAL_IP}"

echo "✓ DNS A records updated:"
echo "  ${ROOT_NAME} → ${EXTERNAL_IP}"
echo "  ${WWW_NAME} → ${EXTERNAL_IP}"

echo "Name servers for your zone (configure at registrar if not already):"
gcloud dns managed-zones describe "${ZONE_NAME}" --format="value(nameServers[])" || true
