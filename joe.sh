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
        # Permission-safe Auto-Detect: Avoid getprop to prevent SELinux permission errors on MuMu
        if [[ "${MY_DEVICE:-}" == "MUMU" ]]; then
            export JOE_ENV="MUMU"
        elif [[ "${MY_DEVICE:-}" == "TERMUX" ]]; then
            export JOE_ENV="TERMUX"
        elif grep -qiE 'intel|amd|hypervisor|vbox|nemu|qemu' /proc/cpuinfo /proc/version 2>/dev/null || \
             [[ "$(uname -m 2>/dev/null)" == "x86_64" || "$(uname -m 2>/dev/null)" == "i686" ]]; then
            export JOE_ENV="MUMU"
        else
            export JOE_ENV="TERMUX"
        fi
        export MY_DEVICE="${MY_DEVICE:-$JOE_ENV}"
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
    TERMUX)
        export SSOT="/data/data/com.termux/files/home/bashscripts"
        export DASHBOARD_DIR="$HOME/dashboard"
        export OBSIDIAN_VAULT="/storage/emulated/0/syncthing/hermes_vault"
        export home="$HOME"
        export nexus_vault="$HOME/nexus_vault"
        export MAIN_SYNC_DIR="$HOME/main_sync"
        export SSH_PORT=8022
        ;;
    MUMU)
        export SSOT="/data/data/com.termux/files/home/bashscripts"
        export DASHBOARD_DIR="$HOME/dashboard"
        export OBSIDIAN_VAULT="/storage/emulated/0/syncthing/hermes_vault"
        export home="$HOME"
        export nexus_vault="$HOME/nexus_vault"
        export MAIN_SYNC_DIR="$HOME/main_sync"
        export SSH_PORT=8020
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
        export SSH_PORT=22
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
        export SSH_PORT=2222
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
export SSH_MUMU_PORT=8020
export SSH_TERMUX_PORT=8022
export SSH_WSL_PORT=22
export SSH_WIN_PORT=2222

if command -v grep >/dev/null 2>&1 && command -v sed >/dev/null 2>&1; then
    _crlf_files="$(grep -rlU $'\r' "$SSOT" --include="*.sh" 2>/dev/null)"
    if [[ -n "$_crlf_files" ]]; then
        _crlf_count=0
        while IFS= read -r _f; do
            sed -i 's/\r$//' "$_f"
            _crlf_count=$((_crlf_count+1))
        done <<< "$_crlf_files"
        # Send to STDERR (not STDOUT) so Powerlevel10k instant prompt
        # is not disturbed — p10k flags ANY stdout during init as a
        # problem and prints a multi-line warning to the user.
        echo "⚠️  CRLF auto-fixed: ${_crlf_count} file(s) → LF (มาจากเครื่องอื่น/Windows)" >&2
    fi

fi

# ── Step 2: Source all modules using SCRIP S_PATH ──

# Environment variables & paths (SSOT: bootstrap/00-env.sh)
[ -f "$SCRIPTS_PATH/bootstrap/00-env.sh" ] && source "$SCRIPTS_PATH/bootstrap/00-env.sh"

# Colors & Styles (must be sourced BEFORE sshd block — it uses cn)
[ -f "$SCRIPTS_PATH/core/01-colors.sh" ] && source "$SCRIPTS_PATH/core/01-colors.sh"

# Auto-start sshd if not running (guarded for git-bash which lacks pgrep)
# Auto-start ssh-agent if not running (needed for tm/tw key auth)
# Auto-start ssh-agent if not running (needed for tm/tw key auth)
if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ssh-add -l &>/dev/null; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# Auto-start sshd guarded by JOE_ENV
if [[ "$JOE_ENV" == "WSL" ]]; then
    # WSL: ใช้ service ssh
    if ! service ssh status >/dev/null 2>&1; then
        sudo service ssh start >/dev/null 2>&1 && cn 10 b "SSH Service (WSL) started successfully." >&2 || cn 9 b "Failed to start SSH Service." >&2
    else
        cn 10 bi "ssh activated port : ${SSH_PORT}" >&2
    fi
elif [[ "$JOE_ENV" == "TERMUX" || "$JOE_ENV" == "MUMU" ]]; then
    # Termux / MuMu: ใช้ sshd binary ตรงๆ
    # NOTE: Termux ใหม่ rename process เป็น "sshd-session" ไม่ใช่ "sshd"
    # → pgrep -x sshd ใช้ไม่ได้ ต้อง check จาก port ที่ bind อยู่จริงแทน
    if ! pgrep -f "sshd.*-p.*${SSH_PORT}" >/dev/null 2>&1; then
        sshd -p "$SSH_PORT" >/dev/null 2>&1 && cn 10 b "SSH Daemon started on port ${SSH_PORT}." >&2 || cn 9 b "Failed to start sshd on port ${SSH_PORT}." >&2
    else
        cn 10 bi "ssh activated port : ${SSH_PORT}" >&2
    fi
fi


#-----SSH and 3-Worlds (tm, tw, push, pull, world)
[ -f "$SCRIPTS_PATH/core/3worlds.sh" ] && source "$SCRIPTS_PATH/core/3worlds.sh"

#-----Aliases
[ -f "$SCRIPTS_PATH/core/02-aliases.sh" ] && source "$SCRIPTS_PATH/core/02-aliases.sh"

#-----Profiiles switching
[ -f "$SCRIPTS_PATH/core/profiles.sh" ] && source "$SCRIPTS_PATH/core/profiles.sh"

#----Theme
[ -f "$SCRIPTS_PATH/core/theme.sh" ] && source "$SCRIPTS_PATH/core/theme.sh"

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

# Init-time startup tasks — wrapped in { ... } >&2 so any console
# output from syncthing_auto / rc_del goes to STDERR only.
# Required by Powerlevel10k instant prompt (sourced first in .zshrc):
# p10k is strict — ANY stdout during zsh init invalidates the
# instant prompt and prints a multi-line warning to the user.
{
  #syncthing_auto
  rc_delete
} >&2

# Disable nounset after everything is loaded — ble.sh restores set -u
# after each command, but joe.sh uses unset variables (dbp, $2, etc.)
set +u

