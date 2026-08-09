#!/bin/bash
# ============================================================
# 02-aliases.sh — All Aliases (CANONICAL)
# ============================================================
# This is the SINGLE SOURCE OF TRUTH for all aliases.
# Organized by category for easy maintenance.
#
# Stage: 5 (after all env vars and functions loaded)
# Dependencies: 00-env.sh (for $oppc, $dbp, etc.)
# ============================================================

# ============================================================
# NAVIGATION & SHORTCUTS
# ============================================================

alias cls='clear'
alias h='help'
alias spy='source $PYTHON_VENV'

# Directory shortcuts (using env vars from 00-env.sh)
alias oppc='cd $oppc'
alias dtpc='cd $dtpc'
alias htm='cd $htm'
alias hwsl='cd $hwsl'
alias hpc='cd $hpc'
alias hmp='cd $hmp'
alias bsc='cd $SCRIPTS_PATH && pwd'
alias cdenp='cd $ENGINES_DIR && pwd'
alias dbp='cd $DASHBOARD_DIR'
alias sdc='cd $SDCARD_PATH && pwd'
# ============================================================
# CONFIGURATION & RELOADING
# ============================================================

# Shell-aware reload (zsh uses .zshrc, bash uses .bashrc)
if [[ -n "${ZSH_VERSION:-}" ]]; then
    alias reload='source "$HOME/.zshrc" && cn 46 b "✓ Config reloaded!"'
else
    alias reload='source "$HOME/.bashrc" && cn 46 b "✓ Config reloaded!"'
fi
alias re="clear && reload"
# ============================================================
# SYSTEM & PROCESS MANAGEMENT
# ============================================================

alias ktmux="tmux kill-server"

fll() {
  
	   fm
		fm ls "$@"
	}
  


# Syncthing (WSL)
alias s-start="(syncthing serve --gui-address=0.0.0.0:${NODE_WSL_ST_PORT:-8385} &)"
alias s-stop="pkill -f 'syncthing serve' && echo 'WSL Syncthing stopped'"
alias s-status="ss -tlnp | grep ${NODE_WSL_ST_PORT:-8385} && echo 'WSL Syncthing: RUNNING' || echo 'WSL Syncthing: STOPPED'"
alias s-log="tail -20 \"$HOME/.local/state/syncthing/syncthing.log\" 2>/dev/null || echo 'No log found'"



# ============================================================
# BUILD & COMPILATION
# ============================================================

alias fbrun="full_pipe"
alias rbdb='rbfe && opdb'

# ============================================================
# PROJECT & SERVICE NAVIGATION
# ============================================================

alias enp="cd $ENGINES_DIR"
alias enpipe="enp && $DASHBOARD_PYTHON pipeline_engine.py"
alias cmdc="cd $dbp/api/engines/cmd-convertor && $DASHBOARD_PYTHON cli_converter.py"

# OpenClaw
alias opjs='d="$(dirname "${OPENCLAW_INDEX_JS:-}")"; [ -n "$d" ] && cd "$d" || echo "OPENCLAW_INDEX_JS not set"'
alias opupdate="pnpm i -g openclaw@latest"

# ============================================================
# DEVELOPMENT & TOOLS
# ============================================================

alias gdb="proot-distro login debian"

# File Manager (loaded via joe.sh → functions/11-bash-manager.sh)
alias fmr="fm help"
alias fmoff="fm learn off"

# User-friendly git (non-IT safe): saves + uploads with plain questions.
# Portable: uses $SSOT when the SSOT config loaded it, else falls back to $HOME/bashscripts.
alias giteasy='bash "${SSOT:-$HOME/bashscripts}/tools/git-easy.sh"'

# ============================================================
# INFRASTRUCTURE & SYNC
# ============================================================

alias loadinfra='[ -f "$SCRIPTS_PATH/sync-infra.sh" ] && source "$SCRIPTS_PATH/sync-infra.sh" || echo "sync-infra.sh not found"'
alias saveinfra='[ -f "$SCRIPTS_PATH/sync-infra.sh" ] && source "$SCRIPTS_PATH/sync-infra.sh" push || echo "sync-infra.sh not found"'

# ============================================================
# ALIASES COMPLETE
# ============================================================
#-------------------CLAUDE CODE--------------------#
  alias opclaude='cd ~/claude-opencode-proxy && python3 proxy.py
'
#--------------------------------------------------#

# ============================================================
# PIPELINE DASHBOARD
# ============================================================
alias pipedash='cd ~/pipeline-dashboard && ~/dashboard/.venv/bin/python3 app.py'
alias pipedash-stop='pkill -f "pipeline-dashboard/app.py" && echo "Dashboard stopped"'

alias merge='source $JOE_ROOT/tools/merge.sh && merge_functions'
