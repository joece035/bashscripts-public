#!/bin/bash
# ============================================================
# safe-edit.sh — Pre-commit guard for bashscripts/
# ============================================================
# Blocks hardcoded ANSI escapes, undefined color vars, and
# duplicated IPs/keys. Use as: bash tools/safe-edit.sh <file>
# or wire into git pre-commit hook.
# ============================================================

set -euo pipefail 2>/dev/null || setopt PIPE_FAIL 2>/dev/null

SSOT_COLORS_FILE="${JOE_CORE:-${HOME}/bashscripts/core}/01-colors.sh"
SSOT_ENV_FILE="${JOE_ROOT:-${HOME}/bashscripts}/bootstrap/00-env.sh"
# V4 allowlist: files allowed to contain raw ANSI (V4 = only color engine + test + tools that need to print before SSOT loaded)
ALLOWLIST=(
    "01-colors.sh"            # THE color engine
    "test_m_animate.sh"       # animation test fixture
    "safe-edit.sh"            # bootstrap tool — prints its own status before SSOT is sourced
    "ssot-audit.sh"           # bootstrap tool — same reason
    "color-chart.sh"          # V4 EXCEPTION: visual demo of 256-color codes — its ENTIRE PURPOSE is to show raw escapes
)

err()   { echo -e "\e[38;5;196m❌ $1\e[0m"; }
ok()    { echo -e "\e[38;5;46m✅ $1\e[0m"; }
warn()  { echo -e "\e[38;5;226m⚠️  $1\e[0m"; }
info()  { echo -e "\e[38;5;75mℹ️  $1\e[0m"; }

if [[ $# -lt 1 ]]; then
    err "Usage: $0 <bash-file-to-check>"
    err "   or: SAFE_EDIT_TARGET=<file> $0"
    exit 2
fi

# Allow passing target via env var (workaround for PowerShell wsl arg-stripping)
target="${1:-$SAFE_EDIT_TARGET}"
target_name="$(basename "$target")"

# Skip allowlist
for allowed in "${ALLOWLIST[@]}"; do
    [[ "$target_name" == "$allowed" ]] && { ok "$target_name is allowlisted"; exit 0; }
done

[[ ! -f "$target" ]] && { err "File not found: $target"; exit 2; }

errors=0

# --- 1. Legacy short-color ANSI escapes (8/16-color codes) ---
# V4 rule (2026-08-03): even 256-color inline (\e[38;5;Nm) is BANNED
# outside 01-colors.sh. Use helpers c()/cn()/color() from 01-colors.sh.
# Only 30-37/40-47/90-97/100-107 short codes are forbidden (and 256-color inline).
# NOTE: ต้องกรอง ;5; ออก เพราะ 256-color เช่น \e[38;5;196m มีเลข 96 ต่อท้าย
# ซึ่ง regex เปล่า ๆ จะจับเป็น 9[0-7] ผิด ๆ
_SHORT_ANSI='\\e\[[0-9;]*[34][0-7]m|\\033\[[0-9;]*[34][0-7]m|\\x1b\[[0-9;]*[34][0-7]m'
bad_lines=$(grep -nE "$_SHORT_ANSI" "$target" 2>/dev/null | grep -vE ';5;[0-9]+m' | head -5)
bad_ansi=$(echo "$bad_lines" | grep -c . || echo 0)
if [[ "$bad_ansi" -gt 0 ]]; then
    err "Found $bad_ansi short-color ANSI escape(s) in $target_name:"
    echo "$bad_lines"
    info "Fix: use cn <color> [style] 'text' from 01-colors.sh (V4 rule)"
    ((errors++))
fi

# --- 1b. V4: inline 256-color anywhere outside 01-colors.sh is BANNED ---
# 256-color: \e[38;5;Nm / \e[48;5;Nm (fg/bg) + \e[1m, \e[2m, \e[3m, \e[4m styles
# Allowed ONLY in 01-colors.sh (the SSOT engine) and test_m_animate.sh (animation test)
_256_ANSI='\\e\[[0-9;]*38;5;[0-9]+m|\\e\[[0-9;]*48;5;[0-9]+m|\\e\[[0-9;]*[0-9]+m|\\033\[[0-9;]*38;5;[0-9]+m|\\033\[[0-9;]*48;5;[0-9]+m|\\x1b\[[0-9;]*38;5;[0-9]+m|\\x1b\[[0-9;]*48;5;[0-9]+m'
if [[ "$target_name" != "01-colors.sh" && "$target_name" != "test_m_animate.sh" ]]; then
    # Filter out comments and the SSOT helper definitions
    bad_inline=$(grep -nE "$_256_ANSI" "$target" 2>/dev/null \
        | grep -vE '^\s*#|^\s*#' \
        | head -10 || true)
    if [[ -n "$bad_inline" ]]; then
        err "V4: inline ANSI escape(s) in $target_name (BANNED outside 01-colors.sh):"
        echo "$bad_inline"
        info "Fix: use cn <color> [style] 'text' from 01-colors.sh"
        info "     c 196 b 'msg' (no newline) | cn 196 b 'msg' (newline)"
        info "     color 196 b 'msg' (legacy)  | rc b 'msg' (random palette)"
        ((errors++))
    fi
fi

# --- 1c. V4: invented local color vars (e.g. _R_OK, _R_BOLD, MY_COLOR, etc.) ---
# Catch patterns like: _R_OK="..." | _R_BOLD="..." | MY_RED="..." | COLOR_X="..."
_LOCAL_COLOR='^[[:space:]]*_[A-Z_]*(OK|WARN|ERR|ERROR|INFO|DIM|BOLD|RESET|COLOR|FG|BG)[A-Z_]*=|^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[Cc]olor[A-Za-z0-9_]*='
if [[ "$target_name" != "01-colors.sh" ]]; then
    bad_local=$(grep -nE "$_LOCAL_COLOR" "$target" 2>/dev/null \
        | grep -E '\\\\e\[|\\\\033\[|\\\\x1b\[' \
        | head -10 || true)
    if [[ -n "$bad_local" ]]; then
        err "V4: invented local color var(s) in $target_name (BANNED):"
        echo "$bad_local"
        info "Fix: remove local var, call c()/cn()/color() directly"
        ((errors++))
    fi
fi

# --- 2. Legacy color aliases not in SSOT ---
for bad in 'RED' 'LRED' 'GREEN' 'LGREEN' 'YELLOW' 'CYAN' 'LCYAN' 'BLUE' 'LBLUE' 'MAGENTA' 'LMAGENTA' 'WHITE' 'GRAY' 'ORANGE' 'BOLD' 'DIM' 'ITALIC' 'UNDERLINE' 'NC' 'RESET' 'PURPLE' 'GYAN'; do
    if grep -qE "\$\{${bad}\}|\$${bad}\b" "$target" 2>/dev/null; then
        err "V2 color var \${$bad} in $target_name — replace with inline 256-color"
        info "Fix: \\e[38;5;Nm ... \\e[0m (see 01-colors.sh cheat sheet)"
        ((errors++))
    fi
done

# --- 3. Syntax check ---
if ! bash -n "$target" 2>/dev/null; then
    err "Bash syntax error in $target_name:"
    bash -n "$target"
    ((errors++))
fi

# --- 4. Hardcoded IPs (10.x, 192.168.x, 172.16-31.x) — flag, not block ---
hard_ips=$(grep -cE '\b(10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+)\b' "$target" 2>/dev/null || echo 0)
if [[ "$hard_ips" -gt 0 ]]; then
    warn "Found $hard_ips hardcoded private IP(s) — should come from 00-env.sh (\$NODE_*_HOST)"
    grep -nE '\b(10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+)\b' "$target" | head -3
fi

# --- 5. Hardcoded Syncthing API keys (32-char hex) ---
if grep -qE '[a-fA-F0-9]{32}' "$target" 2>/dev/null; then
    if grep -qE '(ST_KEY|API_KEY|api_key)[A-Z_]*="[a-fA-F0-9]{32}"' "$target" 2>/dev/null; then
        warn "Found hardcoded Syncthing API key in $target_name"
        info "Fix: source from 00-env.sh (NODE_*_ST_KEY)"
    fi
fi

# --- Summary ---
echo
if [[ $errors -eq 0 ]]; then
    ok "$target_name passes safe-edit guard"
    exit 0
else
    err "$target_name FAILED safe-edit guard ($errors error(s))"
    exit 1
fi
