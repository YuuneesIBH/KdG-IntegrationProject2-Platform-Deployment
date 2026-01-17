#!/bin/bash

# Main Deployment Script - Multi-Team Management
# Provides a menu to deploy, destroy, or create service accounts for different teams

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Available teams
TEAMS=("Team4" "Team8" "Team12")

print_usage() {
  echo -e "${YELLOW}Usage:${NC} $0 [deploy|destroy|status|verify] [Team4|Team8|Team12]"
  echo -e "       or run without args to use the interactive menu"
}

find_team_index() {
  # Returns 1-based index of team name (case-insensitive) or empty if not found
  local name="$1"
  if [ -z "$name" ]; then
    return 1
  fi
  local lower_name
  lower_name="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  local i=1
  for team in "${TEAMS[@]}"; do
    local lower_team
    lower_team="$(echo "$team" | tr '[:upper:]' '[:lower:]')"
    if [ "$lower_team" = "$lower_name" ]; then
      echo "$i"
      return 0
    fi
    ((i++))
  done
  return 1
}

show_menu() {
  echo -e "${BLUE}════════════════════════════════════════${NC}"
  echo -e "${BLUE}   Multi-Team Deployment Management${NC}"
  echo -e "${BLUE}════════════════════════════════════════${NC}"
  echo ""
  echo -e "${YELLOW}1. Enable GCP APIs${NC}"
  echo -e "${YELLOW}2. Create GCP Service Account${NC}"
  echo -e "${YELLOW}3. Deploy${NC}"
  echo -e "${YELLOW}4. Destroy${NC}"
  echo -e "${YELLOW}5. Status${NC}"
  echo -e "${YELLOW}6. Verify${NC}"
  echo -e "${YELLOW}7. Exit${NC}"
  echo ""
  echo -n -e "${GREEN}Select an option [1-7]: ${NC}"
}

show_team_menu() {
  echo ""
  echo -e "${BLUE}Select Team:${NC}"
  local i=1
  for team in "${TEAMS[@]}"; do
    echo -e "${YELLOW}$i. $team${NC}"
    ((i++))
  done
  echo -e "${YELLOW}$i. Back${NC}"
  echo ""
  echo -n -e "${GREEN}Select team [1-$i]: ${NC}"
}

create_service_account() {
  echo ""
  echo -e "${BLUE}=== GCP Service Account Creation ===${NC}"
  echo ""
  read -p "Enter GCP Project ID: " PROJECT_ID
  if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: Project ID cannot be empty${NC}"
    return 1
  fi
  
  read -p "Enter Service Account Name (default: integration-deployment): " SA_NAME
  SA_NAME="${SA_NAME:-integration-deployment}"
  
  KEY_PATH="$PROJECT_ROOT/credentials.json"
  read -p "Enter credentials.json path (default: $KEY_PATH): " CUSTOM_PATH
  if [ -n "$CUSTOM_PATH" ]; then
    KEY_PATH="$CUSTOM_PATH"
  fi
  
  echo ""
  bash "$SCRIPT_DIR/create-gcp-service-account.sh" "$PROJECT_ID" "$SA_NAME" "$KEY_PATH"
  echo ""
}

deploy_team() {
  local team_choice=$1
  local team=${TEAMS[$((team_choice - 1))]}
  local team_scripts="$PROJECT_ROOT/$team/Scripts"
  local team_terraform="$PROJECT_ROOT/$team/Terraform"
  
  if [ ! -d "$team_scripts" ]; then
    echo -e "${RED}Error: Team scripts directory not found: $team_scripts${NC}"
    return 1
  fi
  
  local deploy_script="$team_scripts/deploy-$(echo "$team" | tr '[:upper:]' '[:lower:]').sh"
  if [ ! -f "$deploy_script" ]; then
    echo -e "${RED}Error: Deploy script not found for $team${NC}"
    return 1
  fi
  
  echo ""
  echo -e "${BLUE}=== Deploying $team ===${NC}"
  echo ""
  # Try to ensure kube credentials before running team deploy
  if ! kubectl cluster-info &>/dev/null; then
    if command -v gcloud &>/dev/null; then
      if [ -f "$team_terraform/terraform.tfvars" ]; then
        local proj zone cname
        proj=$(grep -E '^\s*project_id\s*=\s*"' "$team_terraform/terraform.tfvars" | sed -E 's/.*"(.*)".*/\1/')
        zone=$(grep -E '^\s*zone\s*=\s*"' "$team_terraform/terraform.tfvars" | sed -E 's/.*"(.*)".*/\1/')
        cname=$(grep -E '^\s*cluster_name\s*=\s*"' "$team_terraform/terraform.tfvars" | sed -E 's/.*"(.*)".*/\1/')
        if [ -n "$proj" ] && [ -n "$zone" ] && [ -n "$cname" ]; then
          echo -e "${YELLOW}Kubernetes context missing. Fetching GKE credentials...${NC}"
          echo -e "${BLUE}Project:${NC} $proj  ${BLUE}Zone:${NC} $zone  ${BLUE}Cluster:${NC} $cname"
          gcloud config set project "$proj" >/dev/null 2>&1 || true
          gcloud container clusters get-credentials "$cname" --zone "$zone" --project "$proj" || {
            echo -e "${RED}Failed to retrieve GKE credentials. Please run manually:${NC}"
            echo "gcloud container clusters get-credentials $cname --zone $zone --project $proj"
          }
        else
          echo -e "${YELLOW}terraform.tfvars found but missing values for project_id/zone/cluster_name${NC}"
        fi
      else
        echo -e "${YELLOW}terraform.tfvars not found for $team. Skipping auto credentials.${NC}"
      fi
    else
      echo -e "${YELLOW}gcloud CLI not installed. Install it to auto-fetch credentials.${NC}"
    fi
  fi

  # If we still have no cluster context, abort before running team script
  if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}Cannot connect to Kubernetes cluster. Make sure the cluster exists and credentials are fetched.${NC}"
    echo -e "${YELLOW}To create the cluster for $team, run opentofu in ${team_terraform}${NC}"
    echo "  cd $team_terraform"
    echo "  opentofu init && opentofu apply -auto-approve"
    echo -e "${YELLOW}Then re-run: gcloud container clusters get-credentials $cname --zone $zone --project $proj${NC}"
    return 1
  fi

  bash "$deploy_script"
}

destroy_team() {
  local team_choice=$1
  local team=${TEAMS[$((team_choice - 1))]}
  local team_scripts="$PROJECT_ROOT/$team/Scripts"
  
  if [ ! -d "$team_scripts" ]; then
    echo -e "${RED}Error: Team scripts directory not found: $team_scripts${NC}"
    return 1
  fi
  
  local teardown_script="$team_scripts/teardown-$(echo "$team" | tr '[:upper:]' '[:lower:]').sh"
  if [ ! -f "$teardown_script" ]; then
    echo -e "${RED}Error: Teardown script not found for $team${NC}"
    return 1
  fi
  
  echo ""
  echo -e "${YELLOW}⚠️  WARNING: This will destroy all resources for $team${NC}"
  read -p "Are you sure? Type 'yes' to confirm: " confirmation
  
  if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}Destroy cancelled${NC}"
    return 0
  fi
  
  echo ""
  echo -e "${BLUE}=== Destroying $team ===${NC}"
  echo ""
  
  bash "$teardown_script"
}

status_team() {
  local team_choice=$1
  local team=${TEAMS[$((team_choice - 1))]}
  local team_scripts="$PROJECT_ROOT/$team/Scripts"

  if [ ! -d "$team_scripts" ]; then
    echo -e "${RED}Error: Team scripts directory not found: $team_scripts${NC}"
    return 1
  fi

  local status_script="$team_scripts/status.sh"
  if [ ! -f "$status_script" ]; then
    echo -e "${RED}Error: Status script not found for $team${NC}"
    return 1
  fi

  echo ""
  echo -e "${BLUE}=== Status for $team ===${NC}"
  echo ""

  bash "$status_script"
}

verify_team() {
  local team_choice=$1
  local team=${TEAMS[$((team_choice - 1))]}
  local team_scripts="$PROJECT_ROOT/$team/Scripts"

  if [ ! -d "$team_scripts" ]; then
    echo -e "${RED}Error: Team scripts directory not found: $team_scripts${NC}"
    return 1
  fi

  local verify_script=""
  if [ -f "$team_scripts/verify-fixes.sh" ]; then
    verify_script="$team_scripts/verify-fixes.sh"
  elif [ -f "$team_scripts/verify.sh" ]; then
    verify_script="$team_scripts/verify.sh"
  fi

  if [ -z "$verify_script" ]; then
    echo -e "${RED}Error: Verify script not found for $team${NC}"
    return 1
  fi

  echo ""
  echo -e "${BLUE}=== Verify for $team ===${NC}"
  echo ""

  bash "$verify_script"
}

handle_team_action() {
  local action=$1

  show_team_menu
  read -r team_choice

  # Calculate the numeric option for 'Back'
  local team_count=${#TEAMS[@]}
  local back_option=$((team_count + 1))

  # Validate numeric input
  if ! [[ "$team_choice" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Invalid option${NC}"
    return 1
  fi

  if [ "$team_choice" -ge 1 ] && [ "$team_choice" -le "$team_count" ]; then
    case "$action" in
      deploy)
        deploy_team "$team_choice" ;;
      destroy)
        destroy_team "$team_choice" ;;
      status)
        status_team "$team_choice" ;;
      verify)
        verify_team "$team_choice" ;;
      *)
        echo -e "${RED}Unknown action: $action${NC}" ;;
    esac
  elif [ "$team_choice" -eq "$back_option" ]; then
    echo -e "${YELLOW}Going back to main menu${NC}"
  else
    echo -e "${RED}Invalid option${NC}"
  fi
}

main() {
  # CLI short-circuit: allow non-interactive usage
  # Format: ./main.sh <deploy|destroy|status|verify> <Team4|Team8|Team12>
  if [ $# -ge 1 ]; then
    case "$1" in
      deploy|destroy|status|verify)
        if [ -n "$2" ]; then
          local idx
          idx="$(find_team_index "$2")" || true
          if [ -z "$idx" ]; then
            echo -e "${RED}Invalid team: $2${NC}"
            print_usage
            exit 1
          fi
          case "$1" in
            deploy)
              deploy_team "$idx" ;;
            destroy)
              destroy_team "$idx" ;;
            status)
              status_team "$idx" ;;
            verify)
              verify_team "$idx" ;;
          esac
          exit 0
        fi
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
    esac
  fi

  # Check if credentials.json exists
  if [ ! -f "$PROJECT_ROOT/credentials.json" ]; then
    echo -e "${YELLOW}⚠️  Note: credentials.json not found in $PROJECT_ROOT${NC}"
    echo -e "${YELLOW}You can create it using the 'Create GCP Service Account' option${NC}"
    echo ""
  fi
  
  while true; do
    show_menu
    read -r option
    
    case $option in
      1)
        bash "$SCRIPT_DIR/enable-gcp-apis.sh"
        ;;
      2)
        create_service_account
        ;;
      3)
        handle_team_action "deploy"
        ;;
      4)
        handle_team_action "destroy"
        ;;
      5)
        handle_team_action "status"
        ;;
      6)
        handle_team_action "verify"
        ;;
      7)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid option. Please try again.${NC}"
        ;;
    esac
  done
}

main "$@"
