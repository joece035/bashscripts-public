#!/bin/bash
# ============================================================
# 00-env.sh — Environment Variables & Paths (CANONICAL)
# ============================================================
# This is the SINGLE SOURCE OF TRUTH for all environment
# variables. Set by boot.sh Stage 2, after JOE_ENV detected.
#
# NOTE: Core paths (SCRIPTS_PATH, JOE_ENV, hpc, htm, hwsl, 
# NODE_BIN, dbp, OPENCLAW_BIN) are set by boot.sh Stage 0.
# This file ONLY sets derived/secondary variables.
#
# All paths use variables from boot.sh (no hardcoded paths).
# This ensures it works across all environments: WSL, Termux,
# Linux, and Git Bash on Windows.
#
# Stage: 2 (after boot.sh Stage 0 and 00-bootstrap.sh)
# Dependencies: JOE_ENV, hpc, htm, hwsl, dbp, HOME, SCRIPTS_PATH
# ============================================================

# ============================================================
# 1. WORKSPACE PATHS (Derived from JOE_ENV basics)
# ============================================================

case "$JOE_ENV" in
    TERMUX|BST)
         export HERMES_DIR="/data/data/com.termux/files/home/.hermes"
         export PYTHON_VENV="$HOME/.dash_venv/bin/activate"
         export SDCARD_PATH="/storage/emulated/0/"     
         ;;
    WSL)
         export HERMES_DIR="$HOME/.hermes"
         export PYTHON_VENV="$HOME/.venv/bin/activate"
         
         ;;
    GIT-BASH)
         export HERMES_DIR="/mnt/c/Users/User/AppData/Local/hermes"
         export PYTHON_VENV="$hwsl/.venv/bin/activate"
         
         ;;
    *)
         export PYTHON_VENV="$htm/.dash_venv/bin/activate"
         ;;
esac         
         
# ============================================================
# 2. GLOBAL VARIABLE
# ============================================================  
export profile=mom 
export oppc="$hpc/openclaw"
export dpc="$hpc/Desktop"
export dtpc="$hpc/Desktop"          # compat alias ของ dpc
export hmp="${HERMES_DIR:-$HOME/.hermes}"   # AGENT.md: hmp = $HOME/.hermes
export HERMES_LOG_DIR="${HERMES_DIR}/logs"  # log dir สำหรับ tools/hermes.sh
export BRAVE_SEARCH_API_KEY="BSAfPRWzAVe_En3GTQ-cZHcy3MXk8hB"  # Replace with your actual API key
export BRAVE_API_KEY="${BRAVE_SEARCH_API_KEY}"
export ALPHA_DIR="$msync/alpha-workspace"
export alpha=${ALPHA_DIR}
export storage="/storage/emulated/0/" # sdcrd
# ============================================================  
# Dynamic env switching
# ============================================================
ai_bin() {
    local ai_providers=() 

    ai_providers=( "openclaw" "hermes" )

    for ai in "${ai_providers[@]}"; do
        if command -v "$ai" &>/dev/null; then
             case "$ai" in
                "openclaw")
                    export OPENCLAW_BIN="$(which openclaw)"	
                    ;;
                "hermes")
                    export HERMES_BIN="$(which hermes)"
                    ;;
             esac
        else
             case "$ai" in
                "openclaw") export OPENCLAW_BIN ;;
                "hermes")   export HERMES_BIN ;;
             esac
        fi
    done

}
ai_bin
# ============================================================
# 2. SERVICE PATHS & DIRECTORIES
# ============================================================

# Use dbp from boot.sh (already set correctly for environment

export ENGINES_DIR="$DASHBOARD_DIR/api/engines"

# ============================================================
# 3. PYTHON & VIRTUAL ENVIRONMENT
# ============================================================


# Python activation script
export DASHBOARD_PYTHON="$PYTHON_VENV"

# Python I/O encoding
export PYTHONIOENCODING="utf-8"

# ============================================================
# 3.5 MATH HELPER DEFAULTS (used by m() in 00.1-function-tools.sh)
# ============================================================
# Excel-style: default 2 decimals, round-half-up
export MATH_DEFAULT_SCALE="${MATH_DEFAULT_SCALE:-0}"
export MATH_DEFAULT_MODE="${MATH_DEFAULT_MODE:-round}"   # round | up | down

# ============================================================
# 4. NODE & BUILD SETTINGS
# ============================================================

export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache

# ============================================================
# 5. OPENCLAW CONFIGURATION
# ============================================================

export OPENCLAW_ALLOW_INSECURE_PRIVATE_WS=1
export OPENCLAW_NO_RESPAWN=1
export CURRENT_OC_PROFILE="${CURRENT_OC_PROFILE:-None (Default)}"

# ============================================================
# 6. NODE REGISTRY (Tailscale MagicDNS — SSOT for all nodes)
# ============================================================
# Primary identity = Tailscale hostname (MagicDNS).
# IPs are no longer hardcoded — Tailscale resolves them.
# To add a new node: add a NODE_<NAME>_* block below.
#
# Schema per node:
#   HOST      — Tailscale MagicDNS hostname
#   USER      — SSH login user
#   PORT      — SSH port (SSH service port on the node)
#   ST_PORT   — Syncthing GUI port
#   ST_KEY    — Syncthing API key
#   ST_URL    — Syncthing base URL (no trailing slash)
# ============================================================
 device=2KJ2HQ3-IKVNAXI-IRSVMRM-2MITVS4-3TTZS3C-Z5PQFCD-SORNAU7-ALCCRAL
# --- Termux (Android) ---
export NODE_TERMUX_HOST="termux"
export NODE_TERMUX_USER="u0_a331"
export NODE_TERMUX_PORT="8022"
export NODE_TERMUX_ST_PORT="8383"
export NODE_TERMUX_ST_KEY="f4iNwTC6qU4G9neQpzxwztjt7nyykb2n"
export NODE_TERMUX_ST_ID="OJE25GP-CUVXSOC-A2K47O3-GPIYOW5-UFQI4UM-TQD7FLA-45AKEI2-723DRAR"
export NODE_TERMUX_ST_URL="http://${NODE_TERMUX_HOST}:${NODE_TERMUX_ST_PORT}"

# --- WSL (Linux) ---
export NODE_WSL_HOST="wsl"
export NODE_WSL_USER="usercivenz"
export NODE_WSL_PORT="22"
export NODE_WSL_ST_PORT="8385"
export NODE_WSL_ST_KEY="Vf43jjwj2ZsDhLpSaSUDWDnZTroWM6s2"
export NODE_WSL_ST_ID="3S42YWK-JLYGQXU-NR37KDQ-7WFSODG-42TZPEX-XLTGR3W-XNK67EL-KUAKHQG"
export NODE_WSL_ST_URL="http://${NODE_WSL_HOST}:${NODE_WSL_ST_PORT}"

# --- Windows ---
export NODE_WIN_HOST="window"
export NODE_WIN_USER="User"
export NODE_WIN_ST_PORT="8384"
export NODE_WIN_ST_KEY="9AQa4xCCRuZEDs2qDNUY9s6T27NJS9sU"
export NODE_WIN_ST_ID="FJXVHAJ-ORMJNPA-6KAAGRW-ZJC4UN5-ZNY7RWD-EMON3TO-EXBZX3G-YMUXEAA"
export NODE_WIN_ST_URL="http://${NODE_WIN_HOST}:${NODE_WIN_ST_PORT}"

# --- BSTPlayer 12 (Android 14 emulator, Tailscale MagicDNS) ---
export NODE_BST_HOST="bluestack"
export NODE_BST_USER="u0_a104"
export NODE_BST_PORT="8020"
export NODE_BST_ST_PORT="8386"
export NODE_BST_ST_KEY="DCnKoGJ4tRXUqc7UWa44pNvrkiVRshZQ"
export NODE_BST_ST_ID="JAWP2TM-NNLE4IU-GNPGLLP-BSRFFNC-YQ3RKEU-TEDBZIW-5EMZ2ME-V3F7DQB"
export NODE_BST_ST_URL="http://${NODE_BST_HOST}:${NODE_BST_ST_PORT}"

# --- Debian (proot inside Termux) ---
export NODE_DEBIAN_HOST="${NODE_DEBIAN_HOST:-debian}"
export NODE_DEBIAN_USER="${NODE_DEBIAN_USER:-root}"
export NODE_DEBIAN_PORT="${NODE_DEBIAN_PORT:-22}"

# ============================================================
# COMPATIBILITY LAYER — Phase 1
# All legacy variable names re-exported from Node Registry.
# DO NOT remove these until all consumers migrate to NODE_* vars.
# ============================================================

# Termux compat
export TERMUX_IP="$NODE_TERMUX_HOST"
export TERMUX_USER="$NODE_TERMUX_USER"
export TERMUX_PORT="$NODE_TERMUX_PORT"
export TERMUX_TELSCAIL_IP="$NODE_TERMUX_HOST"
export ST_KEY_TERMUX="$NODE_TERMUX_ST_KEY"
export ST_PORT_TERMUX="$NODE_TERMUX_ST_PORT"
export URL_TERMUX="${NODE_TERMUX_ST_URL}/"

# WSL compat
export WSL_IP="$NODE_WSL_HOST"
export WSL_USER="$NODE_WSL_USER"
export WSL_TELSCAIL_IP="$NODE_WSL_HOST"
export ST_KEY_WSL="$NODE_WSL_ST_KEY"
export ST_PORT_WSL="$NODE_WSL_ST_PORT"
export URL_WSL="${NODE_WSL_ST_URL}/"

# --- Windows compat
# WIN_GIT_BASH: path ของ Git Bash บน Windows (ใช้โดย tw() ใน 3worlds.sh)
# Windows OpenSSH default shell = PowerShell — tw() ต้องเรียกผ่าน PS call operator
export WIN_GIT_BASH="${WIN_GIT_BASH:-C:\Program Files\Git\bin\bash.exe}"
export WINDOWS_IP="$NODE_WIN_HOST"
export WINDOWS_USER="$NODE_WIN_USER"
export ST_KEY_WIN="$NODE_WIN_ST_KEY"
export ST_PORT_WIN="$NODE_WIN_ST_PORT"
export URL_WIN="${NODE_WIN_ST_URL}/"

# BSTPlayer compat (Android emulator peer)
export BST_IP="$NODE_BST_HOST"
export BST_USER="$NODE_BST_USER"
export BST_PORT="$NODE_BST_PORT"
export BST_TELSCAIL_IP="$NODE_BST_HOST"
export ST_KEY_BST="$NODE_BST_ST_KEY"
export ST_PORT_BST="$NODE_BST_ST_PORT"
export URL_BST="${NODE_BST_ST_URL}/"

# Debian compat
export DEBIAN_IP="$NODE_DEBIAN_HOST"
export DEBIAN_USER="$NODE_DEBIAN_USER"
export DEBIAN_PORT="$NODE_DEBIAN_PORT"

# ============================================================
# EXPORTS COMPLETE — Ready for use in aliases and functions
# All paths are environment-aware and work across WSL, Termux, Linux, Git Bash
# ============================================================

# --- SHORT CUT FOR JOE-- #
export nx="$nexus_vault"
export USDT_BEP20_BITKUB=0x5C7D1Da0862F8865C328c8CDE22B3C1168dA2740
export SOL_BITKUB=DxX8Z9VhpSVnXqwzyN36qJNtK2dUZEaBh9ExFaP9NM9E
export SOL_METAMAS=AU7vdRgRbcdcULoiXiQ6AfQpb96MDiFXDyEC2YQAS8Bav
export BTC_BITKUB=bc1qxy3jf7sf6gymdd2ucf6lrzl2jyc9p8322dldta
export HOME_ADDRESS='295/3, หมู่ที่​ 2, หมู่บ้าน​ ห้วยหล่อ, ซ.3/1, อำเภอเมืองลำปาง, ต.ชมพู​, จังหวัดลำปาง, 52100'


# ============================================================ 
#--FB PAGE
# ============================================================

# - lookforward
export FACEBOOK_PAGE_TOKEN=EAAXHv5Qk9LwBRAf9v9dZCbwDOyj3MaF0JRAfZCmeGawhLPRaHqAkUYJ2ZA1TtImmtZB68daaAz2nZCm7jllQlqktlLuzDvRhIN13iDNYAcsz0Qx120hZBcujZBtFySG5ZCOWjSDYYaFrk04K5qJDBdSQZB95vIKmysuBY6usmxDPUa4Qv0wbJSiJlc85KUfZBoKzdzm3YY

export FACEBOOK_PAGE_ID=898773833311604

# -- Shpee page คัดแต่สิ่งที่คุณคู้ควร
export SHOPEE_PAGE_TOKEN=EAAWZCSxf8sR8BRPR5y6QFx6OREJbFNVifA9OZAsM9Tluzqk9qDuOa743Y8cJiWckHSLDG8L6rsoKIZCxoMd4qOCw1I1bOIg3C3zwLdnb1AZAGg4H9hE7uj9kreShaDEDmszMyWIgQqRomyMhgDZAcW75CWhnRO87e6XPhQKEsZB3s7Fcvwi8IOLXbXirE7pykGMXR3ZCPmvZBzKEFtFg7pdjPC2vS2XHZBVz3ZA3DUMnoZD

export SHOPEE_PAGE_ID=875311499006764

# ── OpenCode Go zen (Joe's preferred AI provider) ──
# Key pool: แยกตาม profile เพื่อกันปนกันและ track อายุการใช้งาน
# Schema: $OC_KEY_<PROFILE>    — secret (per-profile)
#         $OC_BASE_URL         — OpenCode Go API endpoint (shared)

# ของแม่ (mom) — key ใหม่ต่อวันที่ 2026-07-25
export OC_KEY_MOM="sk-7heYEMJkSh0aU7y9rRJVIl9uMR7zuYQvVtIGMDtYYBQ1LsjUsrqs5RGk3XZz8DlT"

# ของพี่โจ (joe) — key เก่า ใช้ได้ปกติ
export OC_KEY_JOE="sk-Wlrzpk8MeJQ0gdLQ2KMS2HsIchqiQxXO3ZJ2in1qBniPzKHGRgpGkwsz8LDwPcKD"

# OpenCode Zen (joe เท่านั้น — ใช้ Claude Sonnet)
export OC_KEY_ZEN="sk-OARSXUL9bAmKgGlLJx8I5aMdxJpdCQlQFeNJsVhLz9K77sAVfnqukF7Xh5uyKTMx"

# Shared endpoint
export OC_BASE_URL="https://opencode.ai/zen/go/v1"

# Aliases กลาง — backward compat (alias เก่าที่หลายไฟล์เรียกใช้)
# Default follows $profile (mom). Override with:  pf joe  |  pf mom
# ai_profile() ใน joe.sh จะ overwrite ตอนสลับ profile
export OPENCODE_GO_API_KEY="$OC_KEY_MOM"
export OPENCODE_API_KEY="$OC_KEY_MOM"
export OPENCODE_ZEN_API_KEY="$OC_KEY_ZEN"
export OPENCODE_GO_BASE_URL="$OC_BASE_URL"

# ============================================================
# BACKUP — Single Source of Truth for backup paths
# ============================================================
# Override per-env by exporting BACKUP_DIR before sourcing.
# Default: ~/backups (cross-platform: works on WSL, Termux, Git Bash)
# Used by: bkp / bkpi / bkpl / bkls in functions/00.1-function-tools.sh
# ============================================================
export BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"
mkdir -p "$BACKUP_DIR" 2>/dev/null

# ============================================================
# 7. DEFAULT EDITOR (JOE_ENV-aware)
# ============================================================
# SSOT rule: ตั้ง EDITOR/VISUAL ตาม environment เพื่อให้ทุก tool
# (git commit, crontab -e, sudoedit, npm config edit) เรียก editor
# ที่ถูกต้องอัตโนมัติ
#
# Joe's typical flow:
#   Windows Git Bash → ssh WSL (tw) → joe.sh loads → EDITOR=micro
#   WSL/TERMUX  → micro    (GUI-feel terminal editor)
#   GIT-BASH    → code     (VS Code ที่มีอยู่บน Windows) — fallback
#   fallback    → nano
# ============================================================

case "$JOE_ENV" in
    WSL|TERMUX|BST)
        if command -v micro >/dev/null 2>&1; then
            export EDITOR="micro"
            export VISUAL="micro"
        else
            export EDITOR="nano"
            export VISUAL="nano"
        fi
        ;;
    GIT-BASH)
        # micro.exe ติดตั้งยากบน Git Bash → fallback เป็น VS Code
        if command -v code >/dev/null 2>&1; then
            export EDITOR="code --wait"
            export VISUAL="code --wait"
        elif command -v nano >/dev/null 2>&1; then
            export EDITOR="nano"
            export VISUAL="nano"
        else
            export EDITOR="notepad"
            export VISUAL="notepad"
        fi
        ;;
    *)
        export EDITOR="nano"
        export VISUAL="nano"
        ;;
esac

ternux_fresh() {
    pkg update -y && pkg upgrade -y

pkg install -y \
  bash \
  zsh \
  coreutils \
  util-linux \
  procps \
  findutils \
  grep \
  sed \
  gawk \
  diffutils \
  less \
  file \
  which \
  tree \
  ncurses-utils \
  readline \
  bc \
  openssl \
  curl \
  wget \
  rsync \
  openssh \
  git \
  tar \
  gzip \
  bzip2 \
  xz \
  zip \
  unzip \
  p7zip \
  nano \
  vim \
  micro \
  jq \
  yq \
  python \
  nodejs \
  ripgrep \
  fd \
  bat \
  eza \
  tmux
}






