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
alias bsc='cd $SSOT && pwd'
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

ll() {
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

# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
#                       alias                        #
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
alias ssot='cd $SSOT && cdc .'

