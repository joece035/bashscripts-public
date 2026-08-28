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
unbinding(){
    local mode=""
    local target=""

    # parse flags
    while [[ "${1:-}" == -* ]]; do
        case "$1" in
            -a|-f|-af) mode="${1#-}"; shift ;;
            *) break ;;
        esac
    done
    target="${1:-}"
    [ -z "$target" ] && return 0

    # ตรวจ binding type ตาม shell
    local has_alias=0 has_func=0
    case "$JOE_ENV" in
        TERMUX|MUMU)
            local wt
            wt=$(whence -w "$target" 2>/dev/null | cut -d" " -f2)
            [ "$wt" = "alias" ]    && has_alias=1
            [ "$wt" = "function" ] && has_func=1
            ;;
        WSL|GIT-BASH)
            local tt
            tt=$(type -t "$target" 2>/dev/null)
            [ "$tt" = "alias" ]    && has_alias=1
            [ "$tt" = "function" ] && has_func=1
            ;;
        *)
            c 198 b "unknown JOE_ENV: $JOE_ENV"; return 1
            ;;
    esac

    # ลบตาม mode
    local removed=0
    case "$mode" in
        a)
            if (( has_alias )); then
                unalias "$target" 2>/dev/null && removed=1
                c 45 b "done unalias"; cn 10 b "  $target"
            else
                cn 190 b "⚠ '$target' has no alias"; return 1
            fi
            ;;
        f)
            if (( has_func )); then
                unset -f "$target" 2>/dev/null && removed=1
                c 45 b "done unfunction"; cn 10 b "  $target"
            else
                cn 190 b "⚠ '$target' has no function"; return 1
            fi
            ;;
        af)
            if (( has_alias )); then
                unalias "$target" 2>/dev/null && removed=1
                c 45 b "done unalias"; cn 10 b "  $target"
            fi
            if (( has_func )); then
                unset -f "$target" 2>/dev/null && removed=1
                c 45 b "done unfunction"; cn 10 b "  $target"
            fi
            (( removed )) || { c 198 b "⚠ '$target' is not an alias/function"; return 1; }
            ;;
        *)
            # default: ลบตัวที่เจอตัวแรก
            if (( has_alias )); then
                unalias "$target" 2>/dev/null && removed=1
                c 45 b "done unalias"; cn 10 b "  $target"
            elif (( has_func )); then
                unset -f "$target" 2>/dev/null && removed=1
                c 45 b "done unfunction"; cn 10 b "  $target"
            else
                c 198 b "⚠ '$target' is not an alias/function"; return 1
            fi
            ;;
    esac
}




  case "$JOE_ENV" in 
        TERMUX|MUMU) unbinding -a g >/dev/null 2>&1 || true ;;
        WSL) ;;
        GIT-BASH) unbinding -a ll >/dev/null 2>&1 || true ;;  
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
