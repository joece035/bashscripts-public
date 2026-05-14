#!/bin/bash
# ============================================================
# sync-infra.sh — Universal Bashscripts Sync (GitHub Hub)
# Usage: sync-infra          → pull latest from GitHub
#        sync-infra push     → push local changes to GitHub
#        sync-infra status   → show git status
# ============================================================

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'
RED='\033[31m'; BOLD='\033[1m'; NC='\033[0m'

INFRA_DIR="$HOME/bashscripts"
REMOTE_URL="https://github.com/sitthawat035/bashscripts.git"

_si_header() {
  echo -e "${CYAN}${BOLD}============================================${NC}"
  echo -e "${CYAN}${BOLD}  🔄  INFRA SYNC — bashscripts             ${NC}"
  echo -e "${CYAN}${BOLD}============================================${NC}"
  echo -e "  Device : ${YELLOW}${DEVICE_NAME:-$(hostname)}${NC}"
  echo -e "  Dir    : ${INFRA_DIR}"
  echo -e "  Remote : GitHub / sitthawat035/bashscripts"
  echo -e "${CYAN}--------------------------------------------${NC}"
}

_si_check_git() {
  if ! command -v git &>/dev/null; then
    echo -e "${RED}❌ git not installed. Run: pkg install git${NC}"
    exit 1
  fi
  if [[ ! -d "$INFRA_DIR/.git" ]]; then
    echo -e "${YELLOW}⚙️  No git repo found. Cloning from GitHub...${NC}"
    git clone "$REMOTE_URL" "$INFRA_DIR"
    echo -e "${GREEN}✅ Cloned successfully.${NC}"
    exit 0
  fi
}

_si_pull() {
  echo -e "${YELLOW}⬇️  Pulling latest from GitHub...${NC}"
  cd "$INFRA_DIR"

  # Stash local changes if any
  local stashed=0
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}📦 Stashing local changes...${NC}"
    git stash push -m "auto-stash before sync $(date '+%Y%m%d_%H%M%S')"
    stashed=1
  fi

  git pull --rebase origin main
  local exit_code=$?

  if [[ $stashed -eq 1 ]]; then
    echo -e "${YELLOW}📤 Restoring local changes...${NC}"
    git stash pop
  fi

  if [[ $exit_code -eq 0 ]]; then
    echo -e "${GREEN}✅ Pull complete! Infra is up to date.${NC}"
    echo -e "${CYAN}  Tip: Run ${BOLD}'reload'${NC}${CYAN} to apply changes in this terminal.${NC}"
  else
    echo -e "${RED}❌ Pull failed — check conflicts above.${NC}"
    return 1
  fi
}

_si_push() {
  echo -e "${YELLOW}⬆️  Pushing local changes to GitHub...${NC}"
  cd "$INFRA_DIR"

  if git diff --quiet && git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  No changes to push.${NC}"
    return 0
  fi

  git add -A
  local msg="${1:-sync: auto-push from ${DEVICE_NAME:-$(hostname)} $(date '+%Y-%m-%d %H:%M')}"
  git commit -m "$msg"
  git push origin main

  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Push complete!${NC}"
  else
    echo -e "${RED}❌ Push failed.${NC}"
    return 1
  fi
}

_si_status() {
  cd "$INFRA_DIR"
  echo -e "${YELLOW}📋 Git Status:${NC}"
  git status -s
  echo ""
  echo -e "${YELLOW}📜 Last 5 commits:${NC}"
  git log --oneline -5
}

# ---- Main ----
_si_header
_si_check_git

case "${1:-pull}" in
  pull)   _si_pull ;;
  push)   _si_push "$2" ;;
  status) _si_status ;;
  *)
    echo -e "Usage: sync-infra [pull|push|status]"
    echo -e "  pull   — Pull latest from GitHub (default)"
    echo -e "  push   — Push local changes to GitHub"
    echo -e "  status — Show git status"
    ;;
esac
