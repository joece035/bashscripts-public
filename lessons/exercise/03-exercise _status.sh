#!/bin/bash
# ============================================================
# 02-exercise _status.sh — Data providers (Status Renderers)
# ============================================================
# Functions:
# exercise_op_profile   — system status dashboard (SSH, Tailscale, Syncthing, Acode-X)
# exercise_op           — operator profile block
# exercise_oc           — status block
# exercise_jenv         — environment status block
# ============================================================

# ============================================================
# exercise_op_profile — Operator profile dashboard
# ============================================================
exercise_status() {
    local ssh_val ssh_emo
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        ssh_val="ACTIVE"
        ssh_emo="🟢"
    else
        ssh_val="LOCAL"
        ssh_emo="💻"
    fi

    local ts_val
    if command -v tailscale &>/dev/null; then
        if tailscale status &>/dev/null; then
            ts_val="ONLINE"
        else
            ts_val="OFFLINE"
        fi
    else
        ts_val="NO TAILSCALE"
    fi

    local st_val="ONLINE" st_emo="🟢"
    if declare -f _get_syncthing_raw &>/dev/null; then
        local st_raw
        st_raw=$(_get_syncthing_raw 2>/dev/null || echo "UNKNOWN|❓")
        st_val="${st_raw%|*}"
        st_emo="${st_raw#*|}"
    fi

    local axs_val axs_emo
    if pgrep -f axs > /dev/null 2>&1; then
        axs_val="ONLINE"
        axs_emo="🟢"
    else
        axs_val="OFFLINE"
        axs_emo="🔴"
    fi

    if [[ "${JOE_ENV:-}" == "TERMUX" ]]; then
        local exercise_rows=(
            "🌍|JOE_ENV|${JOE_ENV:-UNKNOWN}|📱"
            "🔐|SSH|${ssh_val}|${ssh_emo}"                                    
            "🌐|TAILSCALE|${ts_val}|🌐"
            "📂|CURRENT DIR|$(basename "$PWD")|📂"
            "🔄|SYNCTHING|${st_val}|${st_emo}"
            "🆚|Acode-X|${axs_val}|${axs_emo}"
            "📅|date|$(date | cut -d" " -f1,3,2,6)|📅"
            "🌘|time|$(date | cut -d" " -f4,5)|🕒"
        )
        exercise_dashboard_array "${exercise_rows[@]}"
    else
        local exercise_rows=(
            "🌍|JOE_ENV|${JOE_ENV:-UNKNOWN}|📱"
            "🔐|SSH|${ssh_val}|${ssh_emo}"
            "🌐|TAILSCALE|${ts_val}|🌐"
            "📂|CURRENT DIR|$(basename "$PWD")|📂"  
            "🔄|SYNCTHING|${st_val}|${st_emo}"
            "📅|date|$(date '+%a %d %b %Y')|📅"
            "🌘|time|$(date '+%H:%M:%S')|🕒"
        )
        exercise_dashboard_array "${exercise_rows[@]}"
    fi
}

# ============================================================
# exercise_op — Operator profile block
# ============================================================
exercise_op() {
    local shell_name
    shell_name=$(basename "${SHELL:-bash}")
    
    local exercise_rows=(
        "👤|USER|${USER:-$(whoami)}|🔑"
        "🏠|HOME|${HOME:-~}|📁"
        "🇹🇭|AI MODEL|${OPENCODE_MODEL:-${MODEL:-Claude}}|🌏"
        "🕜|UPTIME|$(uptime -p 2>/dev/null | sed 's/up //' || echo 'N/A')|⏰"
        "🐚|SHELL|${shell_name}|🔧"
        "📅|DATE|$(date '+%Y-%m-%d')|📅"
    )
    exercise_dashboard_array "${exercise_rows[@]}"
}

# ============================================================
# exercise_oc — Custom status block
# ============================================================
exercise_oc() {

    op_profile "$@"
    opstats_data
    
    
    local exercise_rows=(
        "🔵|$spl1|$spr1|$em1"   
        "🟢|$spl2|$spr2|$em2"
        "🟡|$spl3|$spr3|$em3"
        "🔴|$spl4|$spr4|$em4"
    )
    exercise_dashboard_array "${exercise_rows[@]}"
}

# ============================================================
# joe_test — Visual test sweep
# ============================================================
joe_test() {
    local rcb=("yes" "no" "random")
    local offsets=(-1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1)
    local labels=("  leftmost" "  3/4 left" "  middle left" "  1/4 left" "  center" "  1/4 right" "  middle right" "  3/4 right" "  rightmost")
    local i=0
    for off in "${offsets[@]}"; do
        for rc in "${rcb[@]}"; do
            [[ -n "${color:-}" ]] && color lg b "─── OFFSET=$off (${labels[$i]}) BORDER=$rc ───" || echo "─── OFFSET=$off BORDER=$rc ───"
            _THEME[border_random]="$rc"
            _THEME[offset]="$off"
            local exercise_rows=(
                "👤|USER|${USER:-$(whoami)}|🔑"
                "🏠|HOME|${HOME:-~}|📁"
                "🖥️|HOST|${HOSTNAME:-$(hostname)}|🌐"
                "⏱️|UPTIME|$(uptime -p 2>/dev/null | sed 's/up //' || echo 'N/A')|⏱️"
                "🐚|SHELL|${SHELL:-bash}|🔧"
                "📅|DATE|$(date '+%Y-%m-%d')|📅"
            )
            exercise_dashboard_array "${exercise_rows[@]}"
            echo ""
        done
        (( i++ ))
    done
}

# ============================================================
# exercise_jenv — OpenClaw / Env dashboard
# ============================================================
exercise_jenv() {
    
    local exercise_rows=(  
        "⚙️|STATE_DIR|${OPENCLAW_STATE_DIR:-/tmp}|📁"
        "🌐|LOCAL_URL|${OPENCLAW_LOCAL_URL:-http://localhost}|🔗"
        "🤖|MODEL|${OPENCLAW_MODEL:-default}|🧠"
        "⏱️|TIMEOUT|${OPENCLAW_TIMEOUT:-30s}|⏰"
        "🚪|PORT|${OPENCLAW_GATEWAY_PORT:-8080}|🔌"
        "🔑|TOKEN|${OPENCLAW_TOKEN:-set}|🔐"
        "🦁|BRAVE_KEY|${BRAVE_API_KEY:-set}|🔑"
        "🤖|TELEGRAM|${TELEGRAM_BOT_TOKEN:-set}|💬"
        "💬|DISCORD|${DISCORD_BOT_TOKEN:-set}|💬"
        "📂|WORKSPACE|${WORKSPACE:-$PWD}|📁"
        "📦|BIN|${OPENCLAW_BIN:-$(which openclaw)}|⚙️"
        "📜|INDEX_JS|${OPENCLAW_INDEX_JS:-index.js}|📄"
    )
    exercise_dashboard_array "${exercise_rows[@]}"
}
