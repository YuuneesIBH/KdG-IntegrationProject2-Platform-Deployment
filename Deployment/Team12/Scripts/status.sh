#!/bin/bash

##############################################################################
# Team12 Continuous Monitoring Script
# Real-time monitoring of deployment progress
# Usage: bash status.sh
##############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

NAMESPACE="bordspelplatform-12"
REFRESH_INTERVAL=5

status_color() {
  case "$1" in
    "Running") echo -e "${GREEN}" ;;
    "CrashLoopBackOff") echo -e "${RED}" ;;
    "Pending") echo -e "${YELLOW}" ;;
    "Error") echo -e "${RED}" ;;
    *) echo -e "${GRAY}" ;;
  esac
}

ready_color() {
  case "$1" in
    "1/1"|"true") echo -e "${GREEN}" ;;
    "0/1"|"false") echo -e "${YELLOW}" ;;
    *) echo -e "${GRAY}" ;;
  esac
}

clear

echo -e "${CYAN}====================================================================="
echo -e "TEAM12 DEPLOYMENT MONITORING"
echo -e "Real-time pod status (Ctrl+C to exit)"
echo -e "=====================================================================${NC}"

if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}Not connected to Kubernetes cluster${NC}"
  exit 1
fi

CLUSTER_INFO=$(kubectl cluster-info 2>/dev/null | head -1)
CONTEXT=$(kubectl config current-context)

echo -e "${YELLOW}Connected to:${NC} $CONTEXT"
echo -e "${YELLOW}Cluster:${NC}      $CLUSTER_INFO"
echo ""
echo -e "${YELLOW}Monitoring namespace: $NAMESPACE${NC}"
echo -e "${YELLOW}Auto-refresh every ${REFRESH_INTERVAL}s (Press Ctrl+C to stop)${NC}"
echo ""

while true; do
  clear
  echo -e "${CYAN}====================================================================="
  echo -e "TEAM12 DEPLOYMENT MONITORING"
  echo -e "=====================================================================${NC}"
  echo -e "${GRAY}Last updated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo ""

  PODS=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null)
  if [ -z "$PODS" ]; then
    echo -e "${RED}No pods found in namespace $NAMESPACE${NC}"
    echo ""
    sleep $REFRESH_INTERVAL
    continue
  fi

  TOTAL=$(echo "$PODS" | wc -l)
  READY=$(echo "$PODS" | grep "1/1" | wc -l)
  RUNNING=$(echo "$PODS" | grep "Running" | wc -l)
  FAILED=$(echo "$PODS" | grep -E "CrashLoop|Error" | wc -l)

  echo -e "${YELLOW}Summary:${NC}"
  echo -e "  Total Pods: $TOTAL | ${GREEN}Ready: $READY${NC} | ${BLUE}Running: $RUNNING${NC} | ${RED}Failed: $FAILED${NC}"
  echo ""

  echo -e "${YELLOW}Pod Status:${NC}"
  echo ""
  printf "%s\n" "NAME                                     READY  STATUS           RESTARTS AGE"
  echo "-------------------------------------------------------------------------------"

  echo "$PODS" | while read -r line; do
    NAME=$(echo "$line" | awk '{print $1}')
    READY_FIELD=$(echo "$line" | awk '{print $2}')
    STATUS=$(echo "$line" | awk '{print $3}')
    RESTARTS=$(echo "$line" | awk '{print $4}')
    AGE=$(echo "$line" | awk '{print $5}')

    if [ ${#NAME} -gt 40 ]; then
      NAME="${NAME:0:37}..."
    fi

    STATUS_COLOR=$(status_color "$STATUS")
    READY_COLOR=$(ready_color "$READY_FIELD")

    printf "%-40s %b%-6s%b %b%-15s%b %b%-9s%b %s\n" \
      "$NAME" \
      "$READY_COLOR" "$READY_FIELD" "$NC" \
      "$STATUS_COLOR" "$STATUS" "$NC" \
      "$RESTARTS" "$NC" \
      "$AGE"
  done

  echo ""

  EXTERNAL_IP=$(kubectl get svc nginx-gateway-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}External IP: $EXTERNAL_IP${NC}"
    echo ""
  fi

  ERROR_PODS=$(echo "$PODS" | grep -E "CrashLoop|Error" | awk '{print $1}')
  if [ -n "$ERROR_PODS" ]; then
    echo -e "${YELLOW}Pods with issues:${NC}"
    echo "$ERROR_PODS" | while read pod; do
      if [ -n "$pod" ]; then
        RESTARTS=$(kubectl get pod $pod -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
        echo -e "  ${RED}Pod: $pod (restarts: $RESTARTS)${NC}"
      fi
    done
    echo ""
  fi

  echo -e "${GRAY}Press Ctrl+C to stop monitoring | Next refresh in ${REFRESH_INTERVAL}s...${NC}"
  sleep $REFRESH_INTERVAL
done
