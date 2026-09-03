#!/bin/bash
# ============================================================
# 🚀 SSOT Bootstrap Installer — One-Shot Fresh Setup
# ============================================================
# Target Environment: Termux, MuMu, WSL, Git-Bash
# Usage:
#   bash bootstrap/ssot_install.sh [ENV_OVERRIDE]
# ============================================================

set -eo pipefail

# ── [1] DETECT ENVIRONMENT ──
_detect_env() {
    if [[ -n "${1:-}" ]]; then
        echo "$1"
        return
    fi
    if [[ -d "/data/data/com.termux" ]]; then
        if getprop ro.product.model 2>/dev/null | grep -qiE '(MuMu|vphone)'; then
            echo "MUMU"
        else
            echo "TERMUX"
        fi
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        echo "WSL"
    elif [[ -n "${MSYSTEM:-}" ]] || [[ "${OSTYPE:-}" == "msys" ]]; then
        echo "GIT-BASH"
    else
        echo "WSL"
    fi
}

DETECTED_ENV="$(_detect_env "${1:-}")"
export JOE_ENV="$DETECTED_ENV"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   🚀  SSOT Bootstrap Installer                  ║"
printf "║   🌍 Environment : %-30s║\n" "$JOE_ENV"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── [2] TERMUX STORAGE SETUP ──
if [[ "$JOE_ENV" == "TERMUX" || "$JOE_ENV" == "MUMU" ]]; then
    if [[ ! -d "$HOME/storage" ]]; then
        echo "📂 Setting up Termux storage..."
        termux-setup-storage </dev/null || true
    fi
fi

# ── [3] INSTALL CORE PACKAGES (Batch) ──
echo "📦 Installing core prerequisites..."
if command -v pkg >/dev/null 2>&1; then
    pkg install -y git openssh ncurses-utils curl micro iputils-ping neofetch
elif command -v apt-get >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y git openssh-client ncurses-bin curl
    else
        apt-get update -qq && apt-get install -y git openssh-client ncurses-bin curl
    fi
fi

# ── [4] CLONE / UPDATE REPO ──
SSOT_REPO="https://github.com/joece035/bashscripts-public.git"
SSOT_TARGET="$HOME/bashscripts"

if [[ ! -d "$SSOT_TARGET/.git" ]]; then
    echo "📥 Cloning SSOT repository..."
    git clone "$SSOT_REPO" "$SSOT_TARGET"
else
    echo "🔄 SSOT repository already exists at $SSOT_TARGET"
fi

cd "$SSOT_TARGET"

# ── [5] CONFIGURE .env ──
echo "⚙️  Configuring environment variables..."
if [[ ! -f "$HOME/.env" ]]; then
    if [[ -f ".env.example" ]]; then
        cp .env.example "$HOME/.env"
    else
        touch "$HOME/.env"
    fi
fi

# กำหนด JOE_ENV ลงใน ~/.env ให้ตรงกับเครื่องจริง
if grep -q "^export JOE_ENV=" "$HOME/.env" 2>/dev/null; then
    sed -i "s/^export JOE_ENV=.*/export JOE_ENV=\"$JOE_ENV\"/" "$HOME/.env"
else
    echo "export JOE_ENV=\"$JOE_ENV\"" >> "$HOME/.env"
fi
chmod 600 "$HOME/.env"
echo "  ✅ Configured ~/.env (JOE_ENV=$JOE_ENV)"

# ── [6] PERMISSIONS ──
echo "🔑 Updating execution permissions..."
for f in bootstrap/*.sh core/*.sh; do
    [[ -f "$f" ]] && chmod +x "$f"
done
echo "  ✅ Permissions granted"

# ── [7] RUN SETUP & SSH AUDIT ──
echo ""
echo "🔧 Running setup.sh ($JOE_ENV)..."
./bootstrap/setup.sh "$JOE_ENV"

echo ""
echo "🛡️  Running SSH Mesh Self-Healing..."
./bootstrap/ssh_audit.sh --fix

# ── [8] AUTO-START SSHD FOR TERMUX ──
if [[ "$JOE_ENV" == "TERMUX" || "$JOE_ENV" == "MUMU" ]]; then
    SSH_TARGET_PORT="${SSH_PORT:-8022}"
    [[ "$JOE_ENV" == "MUMU" ]] && SSH_TARGET_PORT=8020
    if ! pgrep -f "sshd.*-p.*${SSH_TARGET_PORT}" >/dev/null 2>&1 && ! pgrep -x sshd >/dev/null 2>&1; then
        echo ""
        echo "🔌 Starting local sshd daemon on port ${SSH_TARGET_PORT}..."
        sshd -p "${SSH_TARGET_PORT}" && echo "  ✅ sshd started successfully" || echo "  ⚠️ sshd start failed (run 'sshd -p ${SSH_TARGET_PORT}' manually)"
    fi
fi

# ── [9] SUMMARY & ACTIVATION ──
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "🎉 SSOT Installation and Configuration Complete!"
echo "═══════════════════════════════════════════════════════════"
echo "To activate your environment immediately, run:"
echo ""
echo "    exec bash"
echo "  or"
echo "    source ~/.bashrc"
echo ""
echo "═══════════════════════════════════════════════════════════"
