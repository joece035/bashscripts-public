#!/bin/bash
# ============================================================
# 🚀 JOE'S PERSONAL COMMAND CENTER — Main Entry Point
# ============================================================
# Works on WSL, Termux (incl. MuMu), and Git Bash via single source.
# Detection order: Termux → WSL → Git Bash → MUMU
# ============================================================

# ── Step 0: JOE_ENV detection (fallback — ปกติ set จาก ~/.env หรือ .bashrc) ──
# ค่าที่ใช้ได้: TERMUX | WSL | GIT-BASH | MUMU
if [[ -z "${JOE_ENV:-}" ]]; then
    if [[ -d "/data/data/com.termux" ]]; then
        # Termux (หรือ MuMuPlayer ที่รัน Termux อยู่) — เช็ค build prop แยก
        if grep -qiE "netease|mumu" /system/build.prop 2>/dev/null; then
            export JOE_ENV="MUMU"
        else
            export JOE_ENV="TERMUX"
        fi
    elif grep -qi "microsoft" /proc/version 2>/dev/null; then
        export JOE_ENV="WSL"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        export JOE_ENV="GIT-BASH"
    else
        # Linux ทั่วไป (non-WSL) → ใช้ semantics เดียวกับ WSL
        export JOE_ENV="WSL"
    fi
fi

#-- Global shell refresh
pp() {

    clear
    case $JOE_ENV in
        TERMUX|MUMU) source "$HOME/.zshrc" ;;
        WSL|GIT-BASH) source "$HOME/.bashrc" ;;
    esac
    cn 2 b "RELOADING....$(cn 10 bi "SUCCESSFULLY....!")"
    cn 198 b "$PWD  🛼 🚄"
    cn 45 b "${JOE_ENV:-unknown}"
}
#--- Global constants (machine-independent)



# ── Step 2: Set derived paths based on JOE_ENV ──
case "$JOE_ENV" in
    TERMUX|MUMU)
        export SSOT="$HOME/bashscripts"
        export DASHBOARD_DIR="$HOME/dashboard"
        export OBSIDIAN_VAULT="/storage/emulated/0/syncthing/hermes_vault"
        export home="$HOME"
        export nexus_vault="$HOME/nexus_vault"
        export MAIN_SYNC_DIR="$HOME/main_sync"
        

        ;;
    WSL)
        export SSOT="$HOME/bashscripts"
	    export hpc="/mnt/c/Users/User" 
        export hwsl="${hwsl:-$HOME}"
        export DASHBOARD_DIR="$HOME/dashboard"
        export PYTHON_VENV="${PYTHON_VENV:-$HOME/.venv/bin/activate}"
        export OBSIDIAN_VAULT="$hpc/DESKTOP/obsidian/alphadev_vaults"
        export home="$HOME"
        export nexus_vault="$HOME/nexus_vault"
        export MAIN_SYNC_DIR="$HOME/main_sync"
        ;;
    GIT-BASH)
        export SSOT="$HOME/bashscripts"
        export hpc="$HOME"
        export hwsl="${hwsl:-//wsl.localhost/Ubuntu/home/usercivenz}"
        export DASHBOARD_DIR="$hwsl/dashboard"
        export OBSIDIAN_VAULT="$hpc/DESKTOP/obsidian/alphadev_vaults"
        export home="$hwsl" 
        export nexus_vault="$hpc/DESKTOP/nexus_vault"
        export MAIN_SYNC_DIR="$HOME/DESKTOP/main_sync"
        ;;
esac

# -- Global varialble defined after done env detection process
        export SCRIPTS_PATH="$SSOT"
        export COLOR_PATH="$SSOT"
        export msync="$MAIN_SYNC_DIR"
        export htm="/data/data/com.termux/files/home"

# ── Step 1.5: CRLF SELF-HEAL (กันไฟล์ CRLF ทำ bash พัง) ──
# Syncthing sync ข้ามเครื่อง (WSL ↔ Termux/Acode-X ↔ Win ↔ MuMu)
# ถ้าเครื่องไหนแก้ไฟล์แล้วบันทึกเป็น CRLF (Windows/Acode-X) bash จะ
# syntax error ทันที — ตรงนี้แปลงกลับเป็น LF ให้อัตโนมัติก่อน source
# หมายเหตุ: ถ้า joe.sh ตัวเองเป็น CRLF จะ parse ไม่ผ่านมาถึงตรงนี้
# → ต้องมี guard ใน .bashrc ด้วย (ดู .bashrc section 6)
if command -v grep >/dev/null 2>&1 && command -v sed >/dev/null 2>&1; then
    _crlf_files="$(grep -rlU $'\r' "$SSOT" --include="*.sh" 2>/dev/null)"
    if [[ -n "$_crlf_files" ]]; then
        _crlf_count=0
        while IFS= read -r _f; do
            sed -i 's/\r$//' "$_f"
            _crlf_count=$((_crlf_count+1))
        done <<< "$_crlf_files"
        echo "⚠️  CRLF auto-fixed: ${_crlf_count} file(s) → LF (มาจากเครื่องอื่น/Windows)"
    fi
    
fi

# ── Step 2: Source all modules using SCRIPTS_PATH ──

# Environment variables & paths
[ -f "$SCRIPTS_PATH/00-env.sh" ] && source "$SCRIPTS_PATH/00-env.sh"

# Colors & Styles (must be sourced BEFORE sshd block — it uses cn)
[ -f "$SCRIPTS_PATH/01-colors.sh" ] && source "$SCRIPTS_PATH/01-colors.sh"

# Auto-start sshd if not running (guarded for git-bash which lacks pgrep)
# Auto-start ssh-agent if not running (needed for tm/tw key auth)
if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ssh-add -l &>/dev/null; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
if command -v pgrep >/dev/null 2>&1; then
    if ! pgrep -x "sshd" >/dev/null 2>&1; then
        sshd >/dev/null 2>&1 || true
    fi
else
    # No pgrep (git-bash / WSL busybox) — try service, fall back silently
    service ssh status >/dev/null 2>&1 || service ssh start >/dev/null 2>&1 || true
fi

#-----SSH and 3-Worlds (tm, tw, push, pull, world)
[ -f "$SCRIPTS_PATH/3worlds.sh" ] && source "$SCRIPTS_PATH/3worlds.sh"

#-----Aliases
[ -f "$SCRIPTS_PATH/02-aliases.sh" ] && source "$SCRIPTS_PATH/02-aliases.sh"

#-----Profiiles switching
[ -f "$SCRIPTS_PATH/profiles.sh" ] && source "$SCRIPTS_PATH/profiles.sh"

#----Theme  
[ -f "$COLOR_PATH/theme.sh" ] && source "$COLOR_PATH/theme.sh"

# Function Modules
# Skip Syncthing conflict files (*.sync-conflict-*.sh) — they have broken
# half-merged state and will produce syntax errors when sourced.
# Top-level files only — nested modules (e.g. joe-block/block/*.sh) must
# be sourced by their own entry point to avoid double-source + banner spam.
if [ -d "$SCRIPTS_PATH/functions" ]; then
    for func_file in "$SCRIPTS_PATH"/functions/*.sh; do
        [[ "$func_file" == *.sync-conflict-* ]] && continue
        [ -f "$func_file" ] && source "$func_file"
    done
    # joe-block is a subdir with its own _blk_source_modules() — call it
    # explicitly so block/*.sh are loaded, but cheat_sheet.sh (which prints
    # a huge banner) is NOT auto-sourced.
    if [ -f "$SCRIPTS_PATH/functions/joe-block/entry.sh" ]; then
        source "$SCRIPTS_PATH/functions/joe-block/entry.sh"
    fi
fi

# syncctl — Syncthing ownership controller (sourced as function)
if [ -f "$SCRIPTS_PATH/tools/syncctl/syncctl" ]; then
    source "$SCRIPTS_PATH/tools/syncctl/syncctl"
fi


# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
#                      START UP                      #
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
# m a 50  # offset=50 cols from left (was 0=full-center, looked like 'hang' on slow shells)

syncthing_auto >/dev/null 2>&1
rc_del >/dev/null 2>&1

# Disable nounset after everything is loaded — ble.sh restores set -u
# after each command, but joe.sh uses unset variables (dbp, $2, etc.)
set +u

