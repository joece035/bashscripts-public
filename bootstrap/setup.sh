#!/bin/bash
# ============================================================
# JOE_ENV Bootstrap Script
# ============================================================
# Usage: git clone <repo> && cd JOE_ENV && ./bootstrap/setup.sh
#
# This script:
# 1. Detects your environment (Termux/WSL/Git Bash)
# 2. Sources core modules
# 3. Adds JOE_ENV to your shell profile
# ============================================================

set -e

# ── Detect JOE_ROOT ──
JOE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export JOE_ROOT
export JOE_CORE="$JOE_ROOT/core"
export JOE_FUNCTIONS="$JOE_ROOT/functions"
export JOE_PLUGINS="$JOE_ROOT/plugins"
export JOE_TOOLS="$JOE_ROOT/tools"

echo "🔧 Installing JOE_ENV from: $JOE_ROOT"

# ── Detect Environment ──
if [[ -d "/data/data/com.termux" ]]; then
    JOE_ENV="TERMUX"
elif grep -qi "microsoft" /proc/version 2>/dev/null; then
    JOE_ENV="WSL"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    JOE_ENV="GIT-BASH"
else
    JOE_ENV="WSL"
fi
export JOE_ENV

echo "🌍 Detected environment: $JOE_ENV"

# ── Source core modules ──
echo "📦 Loading core modules..."

if [[ -f "$JOE_CORE/01-colors.sh" ]]; then
    source "$JOE_CORE/01-colors.sh"
    echo "  ✅ Colors loaded"
else
    echo "  ⚠️  01-colors.sh not found"
fi

# ── Add to shell profile ──
case "$JOE_ENV" in
    TERMUX)
        SHELL_RC="$HOME/.zshrc"
        ;;
    WSL|GIT-BASH)
        SHELL_RC="$HOME/.bashrc"
        ;;
    *)
        SHELL_RC="$HOME/.bashrc"
        ;;
esac

# Check if already installed
if grep -q "JOE_ENV" "$SHELL_RC" 2>/dev/null; then
    echo "ℹ️  JOE_ENV already configured in $SHELL_RC"
else
    echo "" >> "$SHELL_RC"
    echo "# ── JOE_ENV ──" >> "$SHELL_RC"
    echo "export JOE_ENV=\"$JOE_ENV\"" >> "$SHELL_RC"
    echo "export JOE_ROOT=\"$JOE_ROOT\"" >> "$SHELL_RC"
    echo "source '$JOE_ROOT/joe.sh'" >> "$SHELL_RC"
    echo "✅ Added JOE_ENV to $SHELL_RC"
fi

# ── Create symlinks for tools (optional) ──
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Link joe command
if [[ ! -f "$BIN_DIR/joe" ]]; then
    ln -sf "$JOE_ROOT/joe.sh" "$BIN_DIR/joe"
    echo "✅ Created symlink: $BIN_DIR/joe → joe.sh"
fi

# ── Summary ──
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ JOE_ENV installed successfully!"
echo ""
echo "To activate now:"
echo "  source $SHELL_RC"
echo ""
echo "Or open a new terminal."
echo "═══════════════════════════════════════════════════════════"
