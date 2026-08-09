#!/bin/bash
# ============================================================
# ssot-audit.sh — Detect drift between SSOT files and consumers
# ============================================================
# Catches: missing vars, missing files, undefined color aliases
# Runs as: bash tools/ssot-audit.sh
# ============================================================

set -uo pipefail 2>/dev/null || setopt PIPE_FAIL 2>/dev/null

ROOT="${1:-${JOE_ROOT:-$HOME/bashscripts}}"
COLORS_FILE="$ROOT/core/01-colors.sh"
ENV_FILE="$ROOT/bootstrap/00-env.sh"
JOE_FILE="$ROOT/joe.sh"

err()   { echo -e "\e[38;5;196m❌ $1\e[0m"; }
ok()    { echo -e "\e[38;5;46m✅ $1\e[0m"; }
warn()  { echo -e "\e[38;5;226m⚠️  $1\e[0m"; }
info()  { echo -e "\e[38;5;75mℹ️  $1\e[0m"; }
sec()   { echo -e "\n\e[1m── $1 ──\e[0m"; }

[[ ! -f "$COLORS_FILE" ]] && { err "01-colors.sh not found at $COLORS_FILE"; exit 2; }
[[ ! -f "$ENV_FILE" ]] && { err "00-env.sh not found at $ENV_FILE"; exit 2; }
[[ ! -f "$JOE_FILE" ]] && { err "joe.sh not found at $JOE_FILE"; exit 2; }

errors=0
warnings=0

# ============================================================
# 1. AUDIT COLOR SSOT
# ============================================================
sec "1. COLOR SSOT AUDIT (01-colors.sh)"

# Extract all defined color vars — use python for reliable parsing
defined_colors=$(python3 -c "
import re
with open('$COLORS_FILE') as f:
    content = f.read()
# Find all uppercase var assignments: VAR='\033...' or VAR='...'
vars = re.findall(r'\b([A-Z_]+)=[\x27\"]', content)
print('\n'.join(sorted(set(vars))))
" 2>/dev/null || awk -F'[= \047\042]+' '/^[A-Z_]+=/{print $1} /[ ;][A-Z_]+=/{print $2}' "$COLORS_FILE" | sort -u)
defined_count=$(echo "$defined_colors" | wc -l)
ok "Defined colors: $defined_count"
echo "$defined_colors" | tr '\n' ' '; echo

# Find all \${SOMETHING} usages in .sh files (potential color refs)
# excluding comments and the SSOT file itself
all_color_refs=$(grep -rhoE '\$\{[A-Z_]+\}' "$ROOT" --include="*.sh" 2>/dev/null \
    | sed 's/[${}]//g' | sort -u)

# For each potential color-ish ref (UPPER_CASE, short), check existence
upper_refs=$(echo "$all_color_refs" | grep -E '^[A-Z][A-Z_]{0,15}$' || true)
# Known legit non-color vars
EXCLUDE_VARS="JOE_ENV|PATH|HOME|TERM|OSTYPE|HOSTNAME|USER|PWD|SHELL|RANDOM|LINENO|UID|GROUPS|FUNCNAME|BASH_SOURCE|BASH_LINENO|SECONDS|PIPESTATUS|BASH_VERSINFO|BASH_VERSION|BASH_COMMAND|HOSTTYPE|MACHTYPE|OPTARG|OPTIND|OPTERR|IFS|PS3|PS4|REPLY|LANG|LC_ALL|EDITOR|VISUAL|PAGER|DISPLAY|XAUTHORITY|HOME|USER|MAIL|LOGNAME|OLDPWD|SHLVL|PPID|_|FUNCNEST|EPERM|ENOENT|EINTR|EIO|EX_USAGE|EX_OK|EX_NOINPUT|EX_NOPERM|EX_CONFIG|EX_DATAERR|EX_NOUSER|EX_NOHOST|EX_UNAVAILABLE|EX_SOFTWARE|EX_OSERR|EX_OSFILE|EX_CANTCREAT|EX_IOERR|EX_TEMPFAIL|EX_PROTOCOL|EX_NOPERM|EX_CONFIG|COLUMNS|LINES|TERMUX_PREFIX|APK|ANDROID_ROOT|ANDROID_DATA|EXTERNAL_STORAGE|MAIN_SYNC_DIR|NODE_|OC_KEY|ST_KEY|ST_PORT|URL_|JOE_BLOCK|DASHBOARD_DIR|HERMES_|PYTHON_|OPENCODE_|SCRIPTS_|COLOR_PATH|COMP_|COMPREPLY|UNIX_PATH|OPENCODE_GO"

for ref in $upper_refs; do
    if [[ "$ref" =~ ^($EXCLUDE_VARS)$ ]]; then continue; fi
    # If name contains common color/style keywords, audit it
    if [[ "$ref" =~ ^(RED|GREEN|BLUE|YELLOW|CYAN|MAGENTA|WHITE|GRAY|ORANGE|PURPLE|GYAN|NC|RESET|BOLD|DIM|ITALIC|UNDERLINE|LRED|LGREEN|LBLUE|LCYAN|LMAGENTA|LWHITE|LGRAY|LBLK)$ ]]; then
        if ! printf '%s\n' "$defined_colors" | grep -qxF "$ref"; then
            err "${ref} used in code but NOT defined in 01-colors.sh"
            ((errors++))
        fi
    fi
done

# Special: legacy short-color ANSI in any file (V3: 256-color inline is ALLOWED)
# NOTE: filter ;5; — 256-color เช่น \e[38;5;196m ต้องไม่โดนจับเป็น short code
_SHORT_ANSI='\\e\[[0-9;]*[34][0-7]m|\\033\[[0-9;]*[34][0-7]m|\\x1b\[[0-9;]*[34][0-7]m'
hardcoded=""
while IFS= read -r f; do
    # มีบรรทัดที่ match short code อย่างน้อย 1 บรรทัดที่ไม่มี ;5; (ไม่ใช่ 256-color)
    if grep -E "$_SHORT_ANSI" "$f" 2>/dev/null | grep -qvE ';5;[0-9]+m'; then
        hardcoded="$hardcoded $f"
    fi
done < <(grep -rlE "$_SHORT_ANSI" "$ROOT" --include="*.sh" 2>/dev/null | grep -v "01-colors.sh" || true)
if [[ -n "$hardcoded" ]]; then
    err "Legacy short-color ANSI escapes found in:"
    echo "$hardcoded" | sed 's/^/    /'
    ((errors++))
else
    ok "No legacy short-color ANSI escapes"
fi

# V4 (2026-08-03): inline 256-color BANNED outside 01-colors.sh
# Match: \e[38;5;Nm / \e[48;5;Nm / \e[1m / \e[2m / \e[3m / \e[4m + \e[0m
# (any ANSI SGR escape except allowlist)
# V4 POLICY: full-audit reports as WARNING (not error) for existing files,
# because there are many legacy files still using inline escapes.
# Per-file safe-edit.sh still BLOCKS (error) — so any NEW file or edit
# must use helper.  Future migration will move these to helper too.
_V4_256='\\e\[[0-9;]*38;5;[0-9]+m|\\e\[[0-9;]*48;5;[0-9]+m|\\033\[[0-9;]*38;5;[0-9]+m|\\033\[[0-9;]*48;5;[0-9]+m|\\x1b\[[0-9;]*38;5;[0-9]+m|\\x1b\[[0-9;]*48;5;[0-9]+m'
v4_offenders=""
while IFS= read -r f; do
    v4_offenders="$v4_offenders $f"
done < <(grep -rlE "$_V4_256" "$ROOT" --include="*.sh" 2>/dev/null \
    | grep -vE "(01-colors\.sh|test_m_animate\.sh|tools/ssot-audit\.sh|tools/safe-edit\.sh)" || true)
if [[ -n "$v4_offenders" ]]; then
    warn "V4: inline 256-color ANSI found (use cn()/c()/color() from 01-colors.sh) — legacy files, refactor over time:"
    echo "$v4_offenders" | sed 's/^/    /'
    ((warnings++))
    info "V4 policy: safe-edit.sh blocks per-file. Full audit only warns (to allow staged migration)."
else
    ok "V4: no inline 256-color escapes outside 01-colors.sh"
fi

# V4: inline style-only ANSI (bold/dim/italic/underline/reset) outside 01-colors.sh
# Pattern: \e[<n>m where n is 0-9 (not 38/48) and not 38;5; / 48;5;
_V4_STYLE='\\e\[[0-9]+m|\\033\[[0-9]+m|\\x1b\[[0-9]+m'
v4_style_offenders=""
while IFS= read -r f; do
    # Only flag if line has a style SGR without ;5; and is not a comment
    if grep -E "$_V4_STYLE" "$f" 2>/dev/null | grep -vE ';5;[0-9]+m|^\s*#' | grep -q .; then
        v4_style_offenders="$v4_style_offenders $f"
    fi
done < <(grep -rlE "$_V4_STYLE" "$ROOT" --include="*.sh" 2>/dev/null \
    | grep -vE "(01-colors\.sh|test_m_animate\.sh|tools/ssot-audit\.sh|tools/safe-edit\.sh)" || true)
if [[ -n "$v4_style_offenders" ]]; then
    warn "V4: inline style ANSI (\\e[Nm) found — use \$(_b)/\$(_d)/\$(_i)/\$(_u)/\$(_r) or cn() — legacy files:"
    echo "$v4_style_offenders" | sed 's/^/    /'
    ((warnings++))
else
    ok "V4: no inline style ANSI outside 01-colors.sh"
fi

# ============================================================
# 2. AUDIT ENV SSOT
# ============================================================
sec "2. ENV SSOT AUDIT (00-env.sh)"

defined_envs=$(grep -oE '^export [A-Z_]+=' "$ENV_FILE" | awk '{print $2}' | tr -d '=' | sort -u)
defined_env_count=$(echo "$defined_envs" | wc -l)
ok "Defined env exports: $defined_env_count"

# Check for hardcoded IPs (10.x, 192.168.x, 172.16-31.x)
hard_ips=$(grep -rlE '\b(10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+)\b' "$ROOT" --include="*.sh" 2>/dev/null \
    | grep -v "00-env.sh" || true)
if [[ -n "$hard_ips" ]]; then
    warn "Hardcoded private IPs found (should use \$NODE_*_HOST):"
    echo "$hard_ips" | sed 's/^/    /'
    ((warnings++))
else
    ok "No hardcoded private IPs"
fi

# Check for hardcoded Syncthing API keys
hard_keys=$(grep -rlE '[a-fA-F0-9]{32}' "$ROOT" --include="*.sh" 2>/dev/null \
    | xargs grep -lE '(ST_KEY|API_KEY|api_key)[A-Z_]*="[a-fA-F0-9]{32}"' 2>/dev/null \
    | grep -v "00-env.sh" || true)
if [[ -n "$hard_keys" ]]; then
    warn "Hardcoded Syncthing API keys found (should use \$NODE_*_ST_KEY):"
    echo "$hard_keys" | sed 's/^/    /'
    ((warnings++))
else
    ok "No hardcoded API keys"
fi

# ============================================================
# 3. AUDIT LOAD ORDER (joe.sh)
# ============================================================
sec "3. LOAD ORDER AUDIT (joe.sh)"

# Get actual source order
actual_order=$(grep -E '^\[ -f .*SCRIPTS_PATH' "$JOE_FILE" 2>/dev/null \
    | grep -oE '/[0-9]+-[a-z]+\.sh|/3worlds\.sh' \
    | sed 's|^/||' \
    | head -10)
expected_order=(
    "00-env.sh"
    "01-colors.sh"
    "3worlds.sh"
    "02-aliases.sh"
    "theme.sh"
)
info "Actual source order (priority files):"
echo "$actual_order" | sed 's/^/    /'

# ============================================================
# 4. AUDIT FUNCTIONS DIRECTORY
# ============================================================
sec "4. FUNCTIONS DIRECTORY AUDIT"

func_dir="$ROOT/functions"
if [[ -d "$func_dir" ]]; then
    func_count=$(ls -1 "$func_dir"/*.sh 2>/dev/null | wc -l)
    ok "Functions module files: $func_count"
    ls -1 "$func_dir"/*.sh 2>/dev/null | xargs -n1 basename | sed 's/^/    /'
else
    err "functions/ directory not found"
    ((errors++))
fi

# ============================================================
# 5. SYNTAX CHECK ALL .sh
# ============================================================
sec "5. SYNTAX CHECK"

syntax_errors=0
# lessons/ = practice files (user), excluded from SSOT audit
while IFS= read -r -d '' f; do
    if ! bash -n "$f" 2>/dev/null; then
        err "Syntax error in: $f"
        bash -n "$f" 2>&1 | head -3 | sed 's/^/    /'
        ((syntax_errors++))
    fi
done < <(find "$ROOT" -name "*.sh" -type f -not -path "*/lessons/*" -print0 2>/dev/null)
if [[ $syntax_errors -eq 0 ]]; then
    ok "All .sh files pass syntax check"
else
    ((errors += syntax_errors))
fi

# ============================================================
# SUMMARY
# ============================================================
echo
echo "═══════════════════════════════════════════════"
if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    ok "SSOT AUDIT PASSED — no drift, no hardcode, no syntax errors"
    exit 0
elif [[ $errors -eq 0 ]]; then
    warn "SSOT AUDIT PASSED with $warnings warning(s)"
    exit 0
else
    err "SSOT AUDIT FAILED — $errors error(s), $warnings warning(s)"
    exit 1
fi
