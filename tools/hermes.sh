#!/bin/bash
# ============================================================
# openclaw.sh — OpenClaw Profile & Gateway Functions
# ============================================================
# Knowledge:  [[nexus_vault/knowledge/wsl-services]] — systemd + openclaw patterns
# See also:  [[nexus_vault/knowledge/bashscripts]] — shell function patterns
# Reference: ~/nexus_vault (sync via syncthing, 127.0.0.1:8384 in WSL)
# ============================================================






hermes_profile() {
    local profile_name="${1:-nexus}"
    case "$profile_name" in 
        "nexus")
          local profile_dir="$HERMES_DIR"
          local CURRENT_PROFILE="${profile_name}"
          shift
          hermes "$@"
          ;;
        *) 
          local profile_dir="$HERMES_DIR/profiles/${profile_name}"
          local CURRENT_PROFILE="${profile_name}"
          shift
          hermes -p "$profile_name" "$@"
           ;;
    esac
}
alias hm_='hermes_profile'








# --- hermes-gw: Start hermes gateway in background ---
hermes-gw() {
    local profile="${1:-}"
    local flag=""
    [[ -n "$profile" ]] && flag="-p $profile"

    printf '%s\n' "$(c 51 b '🚀 Starting Hermes Gateway') ${profile:+(profile: $profile)}"
    nohup bash -c "source ~/.bashrc 2>/dev/null; $HERMES_BIN $flag gateway" \
        > "$HERMES_LOG_DIR/gw-$(date +%Y%m%d_%H%M%S).log" 2>&1 &
    local pid=$!
    echo "$pid" > /tmp/hermes-gw.pid
    printf '%s\n' "$(c 82 b '✅ Gateway started (PID: $pid)')"
    printf '%s\n' "$(c 244 b '   Log: $HERMES_LOG_DIR/gw-*.log')"
}

# --- hermes-dash: Start hermes dashboard in background ---
hermes-dash() {
    local profile="${1:-}"
    local flag=""
    [[ -n "$profile" ]] && flag="-p $profile"

    printf '%s\n' "$(c 51 b '📊 Starting Hermes Dashboard') ${profile:+(profile: $profile)}"
    nohup bash -c "source ~/.bashrc 2>/dev/null; $HERMES_BIN $flag dashboard" \
        > "$HERMES_LOG_DIR/dash-$(date +%Y%m%d_%H%M%S).log" 2>&1 &
    local pid=$!
    echo "$pid" > /tmp/hermes-dash.pid
    printf '%s\n' "$(c 82 b '✅ Dashboard started (PID: $pid)')"
    printf '%s\n' "$(c 244 b '   Log: $HERMES_LOG_DIR/dash-*.log')"
}

# --- hermes-up: Start BOTH gateway + dashboard in background ---
hermes-up() {
    local profile="${1:-}"
    c 51 b "═══════════════════════════════════════"
    printf '%s\n' "$(c 51 b '  🔥 Starting Hermes (Gateway + Dashboard)') ${profile:+(profile: $profile)}"
    c 51 b "═══════════════════════════════════════"
    hermes-gw "$profile"
    sleep 1
    hermes-dash "$profile"
    echo ""
    cn 82 b "✅ Both services started!"
}

# --- hermes-down: Kill all hermes processes ---
hermes-down() {
    cn 226 b "🛑 Stopping all Hermes processes..."
    pkill -f "hermes.*gateway" 2>/dev/null && cn 46 b "  ✓ Gateway stopped" || cn 244 d "    Gateway was not running"
    pkill -f "hermes.*dashboard" 2>/dev/null && cn 46 b "  ✓ Dashboard stopped" || cn 244 d "    Dashboard was not running"
    rm -f /tmp/hermes-gw.pid /tmp/hermes-dash.pid 2>/dev/null
    cn 82 b "🧹 Cleaned up!"
}

# --- hermes-status: Show hermes process status ---
hermes-status() {
    c 51 b "══ Hermes Process Status ══"
    local gw_pid=$(cat /tmp/hermes-gw.pid 2>/dev/null)
    local dash_pid=$(cat /tmp/hermes-dash.pid 2>/dev/null)

    if [[ -n "$gw_pid" ]] && kill -0 "$gw_pid" 2>/dev/null; then
        printf '%s\n' "$(c 46 b '  ● Gateway')  running (PID: $gw_pid)"
    else
        cn 196 b "  ● Gateway  stopped"
    fi

    if [[ -n "$dash_pid" ]] && kill -0 "$dash_pid" 2>/dev/null; then
        printf '%s\n' "$(c 46 b '  ● Dashboard') running (PID: $dash_pid)"
    else
        cn 196 b "  ● Dashboard stopped"
    fi

    # Show any hermes processes
    local count=$(pgrep -fc "hermes" 2>/dev/null)
    printf '%s\n' "$(c 244 d "  Total hermes processes: ${count:-0}")"
}

# --- hermes-restart: Restart gateway + dashboard ---
hermes-restart() {
    local profile="${1:-}"
    hermes-down
    sleep 2
    hermes-up "$profile"
}


p_(){
ss -tln | grep ${1:-9119}
}

hm_db() {
    case "$JOE_ENV" in
    GIT-BASH)
        if pgrep -f "hermes.*dashboard" > /dev/null; then 
        echo "Hermes dashboard is already running"; return; 
        fi 
        hermes -p "${HERMES_DASH_PROFILE:-mook}" dashboard --host 0.0.0.0 --port "${HERMES_DASH_PORT:-2000}" --isolated & 
        ;;

    WSL|TERMUX|MUMU)
        if pgrep -f "hermes.*dashboard" > /dev/null; then
        echo "Hermes dashboard is already running"; return; 
        fi 
        hermes -p "${HERMES_DASH_PROFILE:-alphadev}" dashboard --host 0.0.0.0 --port "${HERMES_DASH_PORT:-3000}" --isolated &   
        
        ;;
    *)
       return
        ;;
    esac
 }