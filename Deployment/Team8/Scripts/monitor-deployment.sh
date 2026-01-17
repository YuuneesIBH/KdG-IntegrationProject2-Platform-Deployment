#!/bin/bash

##############################################################################
# Team 8 Continuous Monitoring Script
# Real-time monitoring of deployment progress
#
# Usage: bash monitor-deployment.sh
##############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

NAMESPACE="bordspelplatform-8"
REFRESH_INTERVAL=5

# Colors for pod status
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

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║           📊 TEAM 8 DEPLOYMENT MONITORING 📊                             ║
║                                                                            ║
║        Real-time pod status and deployment progress                       ║
║        Press Ctrl+C to stop monitoring                                    ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if connected to cluster
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}✗ Not connected to Kubernetes cluster${NC}"
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

# Continuous monitoring
while true; do
  clear
  
  echo -e "${CYAN}"
  cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║ 📊 TEAM 8 DEPLOYMENT MONITORING                                          ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
  
  # Timestamp
  echo -e "${GRAY}Last updated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo ""
  
  # Get all pods
  PODS=$(kubectl get pods -n $NAMESPACE --no-headers 2>/dev/null)
  
  if [ -z "$PODS" ]; then
    echo -e "${RED}✗ No pods found in namespace $NAMESPACE${NC}"
    echo ""
    sleep $REFRESH_INTERVAL
    continue
  fi
  
  # Summary counts
  TOTAL=$(echo "$PODS" | wc -l)
  READY=$(echo "$PODS" | grep "1/1" | wc -l)
  RUNNING=$(echo "$PODS" | grep "Running" | wc -l)
  FAILED=$(echo "$PODS" | grep -E "CrashLoop|Error" | wc -l)
  
  echo -e "${YELLOW}Summary:${NC}"
  echo -e "  Total Pods: $TOTAL | ${GREEN}Ready: $READY${NC} | ${BLUE}Running: $RUNNING${NC} | ${RED}Failed: $FAILED${NC}"
  echo ""
  
  # Pod details
  echo -e "${YELLOW}Pod Status:${NC}"
  echo ""
  echo -e "${BLUE}NAME${NC:0:40}                   ${BLUE}READY${NC}   ${BLUE}STATUS${NC}           ${BLUE}RESTARTS${NC}  ${BLUE}AGE${NC}"
  echo "─────────────────────────────────────────────────────────────────────────────────"
  
  echo "$PODS" | while read -r line; do
    NAME=$(echo "$line" | awk '{print $1}')
    READY=$(echo "$line" | awk '{print $2}')
    STATUS=$(echo "$line" | awk '{print $3}')
    RESTARTS=$(echo "$line" | awk '{print $4}')
    AGE=$(echo "$line" | awk '{print $5}')
    
    # Truncate name if too long
    if [ ${#NAME} -gt 40 ]; then
      NAME="${NAME:0:37}..."
    fi
    
    # Format status colors
    STATUS_COLOR=$(status_color "$STATUS")
    READY_COLOR=$(ready_color "$READY")
    
    printf "%-40s %b%-6s%b %b%-15s%b %b%-9s%b %s\n" \
      "$NAME" \
      "$READY_COLOR" "$READY" "$NC" \
      "$STATUS_COLOR" "$STATUS" "$NC" \
      "$RESTARTS" "$NC" \
      "$AGE"
  done
  
  echo ""
  
  # Show external IP if available
  EXTERNAL_IP=$(kubectl get svc nginx-gateway-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  
  if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}✓ External IP: $EXTERNAL_IP${NC}"
    echo ""
  fi
  
  # Show any pod errors/warnings
  ERROR_PODS=$(echo "$PODS" | grep -E "CrashLoop|Error" | awk '{print $1}')
  
  if [ -n "$ERROR_PODS" ]; then
    echo -e "${YELLOW}⚠ Pods with issues:${NC}"
    echo "$ERROR_PODS" | while read pod; do
      if [ -n "$pod" ]; then
        RESTARTS=$(kubectl get pod $pod -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
        echo -e "  ${RED}✗${NC} $pod (restarts: $RESTARTS)"
      fi
    done
    echo ""
  fi
  
  # Show next refresh
  echo -e "${GRAY}Press Ctrl+C to stop monitoring | Next refresh in ${REFRESH_INTERVAL}s...${NC}"
  
  sleep $REFRESH_INTERVAL
done
