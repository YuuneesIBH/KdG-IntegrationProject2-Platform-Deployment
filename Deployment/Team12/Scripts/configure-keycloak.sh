#!/usr/bin/env bash
set -euo pipefail

# Keycloak bootstrap script for Team12
# - Creates realm, clients, role, assigns role to game service account
# - Retrieves client secrets and patches platform-secrets
# - Restarts dependent deployments to pick up new secrets

NAMESPACE=${NAMESPACE:-bordspelplatform-12}
REALM=${REALM:-stoom}
DOMAIN=${DOMAIN:-stoom-app.com}
KEYCLOAK_SERVICE=${KEYCLOAK_SERVICE:-keycloak-service}
KEYCLOAK_PORT=${KEYCLOAK_PORT:-8180}
KEYCLOAK_CONTEXT=${KEYCLOAK_CONTEXT:-}

FRONTEND_CLIENT=stoom-frontend
BACKEND_CLIENT=stoom-backend
TICTACTOE_CLIENT=tictactoe-backend
CHESS_CLIENT=chess-backend
GAME_ROLE=game

# Redirect URIs / Web origins (adjust if needed)
# Pre-built JSON arrays for kcadm (avoid parsing issues) — set at runtime in main with DOMAIN expanded
FRONTEND_REDIRECTS_JSON=""
FRONTEND_ORIGINS_JSON=""

# Helpers
kc_exec() {
  local pod=$1; shift
  kubectl exec -n "$NAMESPACE" "$pod" -- bash -c "$*"
}

resolve_keycloak_context() {
  local cm_ctx
  cm_ctx=$(kubectl get configmap platform-config -n "$NAMESPACE" -o jsonpath='{.data.KC_HTTP_RELATIVE_PATH}' 2>/dev/null || true)
  if [ -n "${cm_ctx:-}" ] && [ "${cm_ctx}" != "null" ]; then
    KEYCLOAK_CONTEXT="$cm_ctx"
  fi
  if [ -n "${KEYCLOAK_CONTEXT}" ] && [ "${KEYCLOAK_CONTEXT:0:1}" != "/" ]; then
    KEYCLOAK_CONTEXT="/${KEYCLOAK_CONTEXT}"
  fi
  if [ "${KEYCLOAK_CONTEXT}" = "/" ]; then
    KEYCLOAK_CONTEXT=""
  fi
}

kc_login() {
  local pod=$1
  local admin_user=$2
  local admin_pass=$3
  local server_url
  local tried=()
  local ctx

  resolve_keycloak_context
  for ctx in "$KEYCLOAK_CONTEXT" "" "/auth"; do
    if printf '%s\n' "${tried[@]}" | grep -qx "$ctx"; then
      continue
    fi
    tried+=("$ctx")
    if [ "$ctx" = "/" ]; then
      ctx=""
    fi
    server_url="http://${KEYCLOAK_SERVICE}:${KEYCLOAK_PORT}${ctx}"
    if kc_exec "$pod" "/opt/keycloak/bin/kcadm.sh config credentials --server ${server_url} --realm master --user ${admin_user} --password ${admin_pass}"; then
      KEYCLOAK_CONTEXT="$ctx"
      return 0
    fi
  done

  echo "Failed to authenticate to Keycloak (tried context: ${tried[*]})" >&2
  return 1
}

kc() {
  local pod=$1; shift
  kc_exec "$pod" "/opt/keycloak/bin/kcadm.sh $*"
}

get_client_id() {
  local pod=$1 client=$2
  kc "$pod" "get clients -r ${REALM} -q clientId=${client} --fields id --format csv" | tr -d '\r"' | tail -n1
}

get_client_secret() {
  local pod=$1 client_id=$2
  local secret_json
  secret_json=$(kc "$pod" "get clients/${client_id}/client-secret -r ${REALM}")
  echo "$secret_json" | sed -n 's/.*"value" *: *"\([^"]*\)".*/\1/p' | head -n1
}

create_realm_if_missing() {
  local pod=$1
  if kc "$pod" "get realms/${REALM}" >/dev/null 2>&1; then
    echo "Realm ${REALM} exists. Deleting and recreating..."
    kc "$pod" "delete realms/${REALM}" || true
    sleep 2  # Wait for realm deletion to propagate
  fi
  echo "Creating realm ${REALM}..."
  kc "$pod" "create realms -s realm=${REALM} -s enabled=true"
  kc "$pod" "update realms/${REALM} -s registrationAllowed=true -s loginWithEmailAllowed=true" 2>/dev/null || true
}

ensure_role() {
  local pod=$1 role=$2
  if ! kc "$pod" "get roles/${role} -r ${REALM}" >/dev/null 2>&1; then
    kc "$pod" "create roles -r ${REALM} -s name=${role}"
  fi
}

ensure_client_confidential() {
  local pod=$1 client=$2 redirects_json=$3 origins_json=$4
  local id
  id=$(get_client_id "$pod" "$client")
  if [ -z "$id" ]; then
    kc "$pod" "create clients -r ${REALM} -s clientId=${client} -s protocol=openid-connect -s publicClient=false -s serviceAccountsEnabled=true -s directAccessGrantsEnabled=false -s standardFlowEnabled=false"
    id=$(get_client_id "$pod" "$client")
  fi
  kc "$pod" "update clients/${id} -r ${REALM} -s 'redirectUris=${redirects_json}' -s 'webOrigins=${origins_json}'"
  echo "$id"
}

ensure_client_public() {
  local pod=$1 client=$2 redirects_json=$3 origins_json=$4
  local id
  id=$(get_client_id "$pod" "$client")
  if [ -z "$id" ]; then
    kc "$pod" "create clients -r ${REALM} -s clientId=${client} -s protocol=openid-connect -s publicClient=true -s directAccessGrantsEnabled=false -s standardFlowEnabled=true -s 'attributes.\"pkce.enforced\"=true' -s 'attributes.\"pkce.code.challenge.method\"=S256'"
    id=$(get_client_id "$pod" "$client")
  fi
  kc "$pod" "update clients/${id} -r ${REALM} -s 'redirectUris=${redirects_json}' -s 'webOrigins=${origins_json}'"
  echo "$id"
}

assign_role_to_service_account() {
  local pod=$1 client=$2 role=$3
  local uid
  uid=$(kc "$pod" "get users -r ${REALM} -q username=service-account-${client} --fields id --format csv" | tr -d '\r' | tail -n1)
  [ -z "$uid" ] && return 0
  kc "$pod" "add-roles -r ${REALM} --uid ${uid} --rolename ${role}" || true
}

patch_platform_secrets() {
  local platform_secret=$1 ttt_secret=$2 chess_secret=$3
  echo "Patching secrets: PLATFORM=${#platform_secret} TICTACTOE=${#ttt_secret} CHESS=${#chess_secret} chars"
  kubectl patch secret platform-secrets -n "$NAMESPACE" --type merge -p "{\"stringData\":{\"PLATFORM_CLIENT_SECRET\":\"${platform_secret}\",\"TICTACTOE_CLIENT_SECRET\":\"${ttt_secret}\",\"CHESS_CLIENT_SECRET\":\"${chess_secret}\"}}"
}

restart_deployments() {
  echo "Hard restarting backend deployments (delete old pods + new start)..."
  
  # Backend services - hard delete pods to free resources immediately
  kubectl delete pods -n "$NAMESPACE" -l app=platform-backend --ignore-not-found=true >/dev/null 2>&1
  kubectl delete pods -n "$NAMESPACE" -l app=tic-tac-toe-backend --ignore-not-found=true >/dev/null 2>&1
  kubectl delete pods -n "$NAMESPACE" -l app=chess-backend --ignore-not-found=true >/dev/null 2>&1
  
  echo "Waiting 3s for new pods to start..."
  sleep 3
}

main() {
  # find keycloak pod
  local kc_pod
  kc_pod=$(kubectl get pods -n "$NAMESPACE" -l app=keycloak -o jsonpath='{.items[0].metadata.name}')
  if [ -z "$kc_pod" ]; then
    echo "Keycloak pod not found in namespace $NAMESPACE" >&2
    exit 1
  fi

  # get admin creds from platform-secrets
  local admin_user admin_pass
  admin_user=$(kubectl get secret platform-secrets -n "$NAMESPACE" -o jsonpath='{.data.KEYCLOAK_ADMIN}' | base64 -d)
  admin_pass=$(kubectl get secret platform-secrets -n "$NAMESPACE" -o jsonpath='{.data.KEYCLOAK_ADMIN_PASSWORD}' | base64 -d)

  kc_login "$kc_pod" "$admin_user" "$admin_pass"
  create_realm_if_missing "$kc_pod"
  ensure_role "$kc_pod" "$GAME_ROLE"

  # Build JSON arrays now (DOMAIN expanded)
  FRONTEND_REDIRECTS_JSON=$(printf '["https://%s/*"]' "$DOMAIN")
  FRONTEND_ORIGINS_JSON='["+"]'

  local backend_id ttt_id chess_id frontend_id
  backend_id=$(ensure_client_confidential "$kc_pod" "$BACKEND_CLIENT" "$FRONTEND_REDIRECTS_JSON" "$FRONTEND_ORIGINS_JSON")
  ttt_id=$(ensure_client_confidential "$kc_pod" "$TICTACTOE_CLIENT" "$FRONTEND_REDIRECTS_JSON" "$FRONTEND_ORIGINS_JSON")
  chess_id=$(ensure_client_confidential "$kc_pod" "$CHESS_CLIENT" "$FRONTEND_REDIRECTS_JSON" "$FRONTEND_ORIGINS_JSON")
  frontend_id=$(ensure_client_public "$kc_pod" "$FRONTEND_CLIENT" "$FRONTEND_REDIRECTS_JSON" "$FRONTEND_ORIGINS_JSON")



  assign_role_to_service_account "$kc_pod" "$TICTACTOE_CLIENT" "$GAME_ROLE"
  assign_role_to_service_account "$kc_pod" "$CHESS_CLIENT" "$GAME_ROLE" || true

  local backend_secret ttt_secret chess_secret
  backend_secret=$(get_client_secret "$kc_pod" "$backend_id")
  ttt_secret=$(get_client_secret "$kc_pod" "$ttt_id")
  chess_secret=$(get_client_secret "$kc_pod" "$chess_id")

  patch_platform_secrets "$backend_secret" "$ttt_secret" "$chess_secret"
  restart_deployments

  echo "Keycloak realm/clients configured and secrets patched."
}

main "$@"
