# =============================================================================
# OpenClaw on Android — ZSH Config
# Migrated from bash — 2026-05-12
# =============================================================================

# ── Environment Variables ──
export PATH="/data/data/com.termux/files/usr/bin:$HOME/.openclaw-android/node/bin:$HOME/.local/bin:$PATH"
export TMPDIR="$PREFIX/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export OA_GLIBC=1
export CONTAINER=1
export CLAWDHUB_WORKDIR="$HOME/.openclaw/workspace"
export ubt="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/root"
export CPATH="$PREFIX/include/glib-2.0:$PREFIX/lib/glib-2.0/include"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export HERMES_SYNC_ROOT=~/storage/shared/hermes-sync
export MACHINE_NAME=termux-mobile

# ── OpenClaw Completion ──
if [ -f /data/data/com.termux/files/home/.openclaw/completions/openclaw.bash ]; then
    source "/data/data/com.termux/files/home/.openclaw/completions/openclaw.bash"
fi

# ── Oh My Zsh ──
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# (bash-manager.sh sourced later in Aliases section)

# ── Load File Manager bash script (before SSH aliases) ──
if [ -f ~/bashscripts/bash-manager.sh ]; then
    source ~/bashscripts/bash-manager.sh
fi

# ── SSH shortcuts (functions override bash-manager aliases) ──
export TERMUX_USER="u0_a331"
export TERMUX_IP="100.110.26.16"
export WINDOWS_USER="User"
export WINDOWS_IP="100.69.181.45"
export WSL_IP="100.80.195.120"
export WSL_USER="usercivenz"

# SSH shortcuts — unalias first (in case bash-manager.sh set them), then define functions
unalias tm tw wsl 2>/dev/null
tm()  { ssh -p 8022 "${TERMUX_USER}@${TERMUX_IP}" "$@"; }
tw()  { ssh "${WINDOWS_USER}@${WINDOWS_IP}" "$@"; }
wsl() { ssh -i ~/.ssh/id_ed25519_wsl -p 22 "${WSL_USER}@${WSL_IP}" "$@"; }

# ── Aliases ──
alias openclawdata="cd /data/data/com.termux/files/home/.openclaw"
alias gubt="proot-distro login ubuntu"
alias cls='clear'
# Help command (from .bashjoe)
help() {
    echo -e "\033[36m======================================================\033[0m"
    echo -e "   🚀 \033[1mJOE'S MISSION CONTROL - COMMAND LIST\033[0m"
    echo -e "\033[36m======================================================\033[0m"
    echo -e "\033[33m\033[1m🔹 [ CUSTOM FUNCTIONS ]\033[0m"
    echo -e "\033[36m======================================================\033[0m"
    echo -e " Tip: Type \033[32m'h'\033[0m to see this list."
}
alias h='help'

alias pp='reload'
alias reload='source ~/.zshrc && echo "Config reloaded!"'
alias oppc='cd $oppc' 2>/dev/null
alias dtpc='cd $dtpc' 2>/dev/null
alias dbp='cd $dbp' 2>/dev/null
alias hmt='cd $hmt' 2>/dev/null
alias hwsl='cd $hwsl' 2>/dev/null
alias hpc='cd $hpc' 2>/dev/null
alias hubt='cd $hubt' 2>/dev/null
alias hmp='cd $hmp' 2>/dev/null
alias ktmux="tmux kill-server"
alias cmdc='cd $ENGINES_DIR/cmd-convertor && source .venv/bin/activate && python cli_converter.py'
alias enp='cd $ENGINES_DIR'
alias enpipe='enp && source .venv/bin/activate && python pipeline_engine.py'
alias runbuild='cd $dbp/frontend && npm run build && cd ..'
alias opjs="$OPENCLAW_JS"
# File Manager (bash-manager.sh sourced above)
alias fmr="fm help"
alias fmoff="fm learn off"
alias fmon="fm learn on"

# ── Hermes Gateway launcher ──
hmgw() {
    pkill -f "hermes gateway" 2>/dev/null
    pkill -f "hermes dashboard" 2>/dev/null
    sleep 1
    mkdir -p ~/.hermes/logs
    hermes gateway &>/dev/null &
    hermes dashboard &>/dev/null &
    echo "Hermes started (background)"
}

# ── Profile Switcher ──
op1() { export OPENCLAW_STATE_DIR="$HOME/.openclaw-1"; export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"; export CURRENT_OC_PROFILE="Profile 1"; cd "$OPENCLAW_STATE_DIR"; }
op2() { export OPENCLAW_STATE_DIR="$HOME/.openclaw-2"; export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"; export CURRENT_OC_PROFILE="Profile 2"; cd "$OPENCLAW_STATE_DIR"; }
op3() { export OPENCLAW_STATE_DIR="$HOME/.openclaw-3"; export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"; export CURRENT_OC_PROFILE="Profile 3"; cd "$OPENCLAW_STATE_DIR"; }
op4() { export OPENCLAW_STATE_DIR="$HOME/.openclaw-4"; export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"; export CURRENT_OC_PROFILE="Profile 4"; cd "$OPENCLAW_STATE_DIR"; }
op5() { export OPENCLAW_STATE_DIR="$HOME/.openclaw-5"; export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"; export CURRENT_OC_PROFILE="Profile 5 (Fah)"; cd "$OPENCLAW_STATE_DIR"; }
op6() { export OPENCLAW_STATE_DIR="$HOME/.openclaw-6"; export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"; export CURRENT_OC_PROFILE="Profile 6 (Fon)"; cd "$OPENCLAW_STATE_DIR"; }
op7() { export OPENCLAW_STATE_DIR="$HOME/.openclaw-7"; export OPENCLAW_WORKSPACE="$OPENCLAW_STATE_DIR/workspace"; export CURRENT_OC_PROFILE="Profile 7 (J1)"; cd "$OPENCLAW_STATE_DIR"; }
opreset() { unset OPENCLAW_STATE_DIR OPENCLAW_WORKSPACE; export CURRENT_OC_PROFILE="None (Cleared)"; }

# ── Utils ──
fp() { local p=$1; [ -z "$p" ] && echo "Usage: fp <port>" && return 1; ss -tlnp "sport = :$p" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1 | xargs -I{} echo "Port $p -> PID {}"; }
kk()  { killall -9 termux-info 2>/dev/null; pkill -9 -u $(whoami) 2>/dev/null; }
kkk() { kill -9 $(pgrep -f "python|node" 2>/dev/null) 2>/dev/null; echo "Cleaned"; }
kkkk() {
    echo -e "\033[31m☠️ SYSTEM PURGE (Python/Node/CMD)\033[0m"
    taskkill.exe /F /IM python.exe /T /FI "STATUS eq RUNNING" 2>/dev/null
    taskkill.exe /F /IM node.exe /T /FI "STATUS eq RUNNING" 2>/dev/null
    taskkill.exe /F /IM cmd.exe /T /FI "STATUS eq RUNNING" 2>/dev/null
    echo -e "\033[32m✅ All targets neutralized.\033[0m"
}
check-tm() { ping -c 1 100.110.26.16 &>/dev/null && echo "Mobile ONLINE" || echo "Mobile OFFLINE"; }
recon() { adb connect "100.110.26.16:5555" 2>/dev/null; echo "ADB connected"; }

opdb() {
    local dash_path="$HOME/dashboard"
    local venv_python="$dash_path/.venv/bin/python"
    if [ -d "$dash_path" ]; then
        echo "Launching Dashboard..."
        cd "$dash_path"
        if [ -f "$venv_python" ]; then
            "$venv_python" server.py &
        else
            python3 server.py &
        fi
        echo "Dashboard started (http://localhost:5050)"
    else echo "Dashboard path not found: $dash_path"; fi
}

tsc() {
    local base_path="$HOME/dashboard"
    local venv_python="$base_path/.venv/bin/python"
    local script_path="api/engines/trend_scan/daily_trend_scan.py"
    if [ -f "$base_path/$script_path" ]; then
        echo "Starting Trend Scan..."
        cd "$base_path"
        "$venv_python" "$script_path"
        cd - >/dev/null
        echo "Trend Scan done!"
    else echo "Not found: $base_path/$script_path"; fi
}

# ── fastfetch on start ──
fastfetch --config termux
