#!/bin/bash
# ============================================================
# openclaw.sh — OpenClaw Profile & Gateway Functions
# ============================================================
# Knowledge:  [[nexus_vault/knowledge/wsl-services]] — systemd + openclaw patterns
# See also:  [[nexus_vault/knowledge/bashscripts]] — shell function patterns
# Reference: ~/nexus_vault (sync via syncthing, 127.0.0.1:8384 in WSL)
# ============================================================



if [[ "$JOE_ENV" == "TERMUX" || "$JOE_ENV" == "MUMU" ]]; then
    export OP_DIR="$htm"

elif [[ "$JOE_ENV" == "GIT-BASH" ]]; then
    export OP_DIR="$HOME"

else
    export OP_DIR="$hwsl"
fi


op_profile() {
    export profile_num="${1:-0}"
    case "$profile_num" in 
        0)
          export profile_num=0  
          local pro=".openclaw"
          local oc_profile="${PROFILE_NAME:-default}"
          ;;
        *) 
          local pro=".openclaw-$profile_num"
          local oc_profile="${PROFILE_NAME:-profile-$profile_num}"
           ;;
    esac
     [ -d "$OP_DIR/$pro" ] && cd "$OP_DIR/$pro" || { cn r b "Please set .env file for ${oc_profile}" ; return 0 ; }
    
  if [ -f "$OP_DIR/$pro/.env" ]; then
      set -a
      source "$OP_DIR/$pro/.env"
      set +a
  else
      cn lr b "!SETUP .env first"
      return 0
  fi
  
    export OPENCLAW_STATE_DIR="$OP_DIR/$pro"
    export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"
    export OP_ENV="$OPENCLAW_STATE_DIR/.env"
    
  if [[ -d "$OPENCLAW_STATE_DIR" ]]; then
    cd "$OPENCLAW_STATE_DIR"
  else 
    cn lr b "OpenClaw profile ${oc_profile} doesn't exist"
    return 0
    
  fi 
  

    
}
oc(){
   op_profile "$@"
   opstatus2
}



# ============================================================
# OpenClaw Gateway & Dashboard Functions
# ============================================================

op() { 

    local openclaw_="$(basename  $(which openclaw))"

   if [ $# -eq 0 ]; then
   $openclaw_ gateway
   else
      if ! command -v openclaw >/dev/null 2>&1; then
         local profile_number=${1:-$profile_num}
         local port=${2:-$OPENCLAW_GATEWAY_PORT}
         oc ${profile_number}
         $openclaw_ gateway --port ${port}
      else
         $openclaw_ "$@"
      fi
   fi
}
# ============================================================
# OpenClaw Fast Configurations
# ============================================================
opc(){

local mode=${1:-model}
case "$1" in
    m|model)
        openclaw config set agents.defaults.model.primary "${2:-$OPENCLAW_MODEL}"
        export OPENCLAW_MODEL="${2:-$OPENCLAW_MODEL}"
        cn lg b "✅ Model set to ${OPENCLAW_MODEL}"
        ;;
    tele|telegram)
        local mode2=${2:-add}
        if [[ "$mode2" == "add" ]]; then
            op channels ${mode2} --channel telegram --token "${3:-$TELEGRAM_BOT_TOKEN}"
            cn lg b "✅ Telegram bot token set"
        elif [[ "$mode2" == "remove" || "$mode2" == "del" ]]; then
            op channels ${mode2} --channel telegram
            cn lg b "✅ Telegram bot token removed"
        else
            cn r b "❌ Invalid mode. Use 'a dd' or 'remove'"
        fi
        ;;
    *)
        echo "usage: opc {mode}"
        ;;
esac
} 
 



# ============================================================
# Hermes Gateway & Dashboard Functions
# ============================================================


# --- OPENCLAW SERVICE ---#
# Upgraded version uses getopts (see [[nexus_vault/knowledge/bashscripts]] for pattern)
# Knowledge: [[nexus_vault/knowledge/wsl-services]] — systemd --user pattern
openclaw_service() {
    local OPTIND=1
    local force=false show_status=false
    while getopts "fs" opt; do
        case $opt in
            f) force=true ;;
            s) show_status=true ;;
            \?) echo "usage: openclaw_service [-fs] {on|off}" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    case "${1:-off}" in
        on)
            systemctl --user enable --now openclaw-gateway
            cn lg b "Start Openclaw Gateway auto service"
            ;;
        off)
            systemctl --user disable --now openclaw-gateway
            cn r b "Stop Openclaw Gateway auto service"
            ;;
        *)
            echo "usage: openclaw_service [-fs] {on|off}" >&2
            return 1
            ;;
    esac
    $show_status && systemctl --user status openclaw-gateway --no-pager
}
alias opserv='openclaw_service'
# --- END OPENCLAW SERVICE ---#
