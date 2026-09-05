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





  case "$_SHELL" in 
        zsh) unbinding -a g >/dev/null 2>&1 || true ;;
        bash) unbinding -a ll >/dev/null 2>&1 || true ;;  
  esac


alias spy='source $PYTHON_VENV'

# Directory shortcuts (using env vars from 00-env.sh)

alias htm='cd $htm'
alias hwsl='cd $HWSL'
alias hpc='cd $hpc'
alias hmp='cd $hmp'
alias bsc='cd $SSOT && pwd'
alias cdenp='cd $ENGINES_DIR && pwd'
alias dbp='cd $DASHBOARD_DIR'
alias sdc='cd $SDCARD_PATH && pwd'
alias cdboom='cd $boom'
alias bkboom='cd $bk_boom'
# ============================================================
# CONFIGURATION & RELOADING
# ============================================================

# Shell-aware reload (zsh uses .zshrc, bash uses .bashrc)


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
alias envm='bash "$SSOT/tools/env-manager.sh"'
alias envmgr='bash "$SSOT/tools/env-manager.sh"'



alias statscal='python3 "$SSOT/tools/statscal/statscal.py"'
alias wr='python3 "$SSOT/tools/statscal/statscal.py"'

# ============================================================
# SSOT SECRET VAULT
# ============================================================
alias vault='${SSOT:-$HOME/bashscripts}/tools/ssot-vault.sh'
alias ssot-vault='${SSOT:-$HOME/bashscripts}/tools/ssot-vault.sh'
