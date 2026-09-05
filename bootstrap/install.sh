#!/bin/bash
# ============================================================
# SSOT Bootstrap Installer — Single Entry Point
# ============================================================
# One-shot installer for the bashscripts ecosystem.
# Works on: Termux, MuMu, WSL, Git Bash.
#
# Usage:
    
#   curl -fsSL https://raw.githubusercontent.com/joece035/bashscripts-public/main/bootstrap/install.sh | bash
#
# Or clone first, then run:
#   git clone https://github.com/joece035/bashscripts-public.git ~/bashscripts
#   bash ~/bashscripts/bootstrap/install.sh
#
# Idempotent: safe to re-run. Skips completed steps.
# ============================================================

set -euo pipefail

# ── Minimal color helpers (no dependency on 01-colors.sh yet) ──
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && tput sgr0 >/dev/null 2>&1; then
    _BOLD="$(tput bold)"; _RESET="$(tput sgr0)"
    _GREEN="$(tput setaf 2)"; _YELLOW="$(tput setaf 3)"
    _RED="$(tput setaf 1)"; _CYAN="$(tput setaf 6)"
else
    _BOLD=""; _RESET=""; _GREEN=""; _YELLOW=""; _RED=""; _CYAN=""
fi

log()  { printf '%s==>%s %s\n' "${_BOLD}${_CYAN}" "${_RESET}" "$*"; }
ok()   { printf '   %s✓%s %s\n' "${_GREEN}" "${_RESET}" "$*"; }
warn() { printf '   %s!%s %s\n' "${_YELLOW}" "${_RESET}" "$*" >&2; }
die()  { printf '%s✗%s %s\n' "${_BOLD}${_RED}" "${_RESET}" "$*" >&2; exit 1; }

# ============================================================
# STAGE 0 — Detect Environment
# ============================================================
detect_joe_env() {
    # Allow override via argument or MY_DEVICE env var
    if [[ -n "${1:-}" ]]; then
        echo "$1"
        return
    fi
    if [[ -n "${MY_DEVICE:-}" ]]; then
        echo "$MY_DEVICE"
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
        echo "WSL"  # safe default
    fi
}

log "Stage 0: Detecting environment"
JOE_ENV="$(detect_joe_env "${1:-}")"
export JOE_ENV
ok "Environment: $JOE_ENV"

# ============================================================
# STAGE 1 — Locate or Clone Repository
# ============================================================
SSOT="${SSOT:-$HOME/bashscripts}"

if [[ -f "$SSOT/joe.sh" ]]; then
    ok "SSOT repo found at $SSOT"
else
    log "Stage 1: Cloning SSOT repository"
    if [[ -d "$SSOT/.git" ]]; then
        warn "Partial repo at $SSOT (no joe.sh) — removing and re-cloning"
        rm -rf "$SSOT"
    fi

    REPO_URL="https://github.com/joece035/bashscripts-public.git"
    if command -v git >/dev/null 2>&1; then
        git clone --depth=1 "$REPO_URL" "$SSOT" || die "git clone failed"
    else
        warn "git not found — attempting HTTPS download"
        command -v curl >/dev/null 2>&1 || die "Neither git nor curl available"
        TMPDIR="$(mktemp -d)"
        curl -fsSL "${REPO_URL%.git}/archive/refs/heads/main.tar.gz" \
            | tar -xz -C "$TMPDIR" || die "Download failed"
        mv "$TMPDIR/bashscripts-main" "$SSOT"
        rm -rf "$TMPDIR"
    fi
    ok "Repository cloned to $SSOT"
fi

# Ensure we're working from the canonical SSOT path
cd "$SSOT"

# ============================================================
# STAGE 2 — Create ~/.env (idempotent)
# ============================================================
log "Stage 2: Configuring ~/.env"
ENV_FILE="$HOME/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    if [[ -f "$SSOT/.env.example" ]]; then
        cp "$SSOT/.env.example" "$ENV_FILE"
        ok "Created ~/.env from .env.example"
    else
        touch "$ENV_FILE"
        ok "Created empty ~/.env"
    fi
else
    ok "~/.env already exists"
fi

# Pin JOE_ENV in ~/.env (append or update, never clobber)
if grep -q "^export JOE_ENV=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s/^export JOE_ENV=.*/export JOE_ENV=\"$JOE_ENV\"/" "$ENV_FILE"
    ok "~/.env: JOE_ENV=$JOE_ENV (updated)"
else
    printf '\n# ── SSOT Bootstrap (auto-detected) ──\nexport JOE_ENV="%s"\n' "$JOE_ENV" >> "$ENV_FILE"
    ok "~/.env: JOE_ENV=$JOE_ENV (added)"
fi

# Symlink $SSOT/.env → ~/.env (so joe.sh / 00-env.sh can find it)
if [[ ! -L "$SSOT/.env" ]]; then
    ln -sf "$ENV_FILE" "$SSOT/.env"
    ok "Symlinked $SSOT/.env → ~/.env"
fi

chmod 600 "$ENV_FILE" 2>/dev/null || true

# ============================================================
# STAGE 3 — Wire Shell Profile
# ============================================================
log "Stage 3: Wiring shell profile"

# Determine which profile templates to symlink
case "$JOE_ENV" in
    TERMUX)
        PROFILE_DIR="$SSOT/profiles/termux"
        SHELL_RC="$HOME/.zshrc"    # Termux uses zsh
        BASH_RC="$HOME/.bashrc"
        ;;
    MUMU)
        PROFILE_DIR="$SSOT/profiles/mumu"
        SHELL_RC="$HOME/.zshrc"
        BASH_RC="$HOME/.bashrc"
        ;;
    WSL)
        PROFILE_DIR="$SSOT/profiles/wsl"
        SHELL_RC="$HOME/.bashrc"   # WSL default is bash
        BASH_RC="$HOME/.bashrc"
        ;;
    GIT-BASH)
        PROFILE_DIR="$SSOT/profiles/git-bash"
        SHELL_RC="$HOME/.bashrc"
        BASH_RC="$HOME/.bashrc"
        ;;
    *)
        PROFILE_DIR="$SSOT/profiles/wsl"
        SHELL_RC="$HOME/.bashrc"
        BASH_RC="$HOME/.bashrc"
        ;;
esac

# Symlink primary shell profile
_profile_src="$PROFILE_DIR/$(basename "$SHELL_RC")"
if [[ -f "$_profile_src" ]]; then
    if [[ -L "$SHELL_RC" ]]; then
        _current_target="$(readlink "$SHELL_RC")"
        if [[ "$_current_target" == "$_profile_src" ]]; then
            ok "$SHELL_RC already linked to correct profile"
        else
            ln -sf "$_profile_src" "$SHELL_RC"
            ok "$SHELL_RC re-linked → $_profile_src"
        fi
    elif [[ -f "$SHELL_RC" ]]; then
        _backup="${SHELL_RC}.bak.$(date +%s)"
        cp "$SHELL_RC" "$_backup"
        warn "Backed up existing $SHELL_RC → $_backup"
        ln -sf "$_profile_src" "$SHELL_RC"
        ok "$SHELL_RC → $_profile_src (symlinked, original backed up)"
    else
        ln -sf "$_profile_src" "$SHELL_RC"
        ok "$SHELL_RC → $_profile_src (symlinked)"
    fi
else
    warn "Profile template not found: $_profile_src"
    warn "You may need to manually source joe.sh in $SHELL_RC"
fi

# Also symlink .bashrc if different from primary and template exists
if [[ "$SHELL_RC" != "$BASH_RC" ]]; then
    _bashrc_src="$PROFILE_DIR/.bashrc"
    if [[ -f "$_bashrc_src" ]] && [[ ! -L "$BASH_RC" ]]; then
        _backup="${BASH_RC}.bak.$(date +%s)"
        cp "$BASH_RC" "$_backup" 2>/dev/null || true
        ln -sf "$_bashrc_src" "$BASH_RC"
        ok "$BASH_RC → $_bashrc_src (symlinked)"
    fi
fi

# ============================================================
# STAGE 4 — Create Tool Symlinks
# ============================================================
log "Stage 4: Creating tool symlinks"

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# joe command
if [[ ! -L "$BIN_DIR/joe" ]]; then
    ln -sf "$SSOT/joe.sh" "$BIN_DIR/joe"
    chmod +x "$SSOT/joe.sh"
    ok "Created: $BIN_DIR/joe → joe.sh"
else
    ok "$BIN_DIR/joe already linked"
fi

# syncctl command
if [[ ! -L "$BIN_DIR/syncctl" ]] && [[ -f "$SSOT/tools/syncctl/syncctl" ]]; then
    ln -sf "$SSOT/tools/syncctl/syncctl" "$BIN_DIR/syncctl"
    chmod +x "$SSOT/tools/syncctl/syncctl"
    ok "Created: $BIN_DIR/syncctl → tools/syncctl/syncctl"
fi

# ============================================================
# STAGE 5 — Termux / MuMu: Storage + Packages
# ============================================================
if [[ "$JOE_ENV" == "TERMUX" || "$JOE_ENV" == "MUMU" ]]; then
    log "Stage 5: Termux setup"

    # Storage access
    if [[ ! -d "$HOME/storage" ]]; then
        log "  Requesting storage access..."
        termux-setup-storage </dev/null || warn "termux-setup-storage failed (approve manually)"
    else
        ok "  Storage already accessible"
    fi

    # Essential packages (best-effort, don't fail the install)
    if command -v pkg >/dev/null 2>&1; then
        log "  Installing essential packages..."
        pkg install -y git openssh curl jq rsync 2>/dev/null \
            && ok "  Core packages installed" \
            || warn "  Some packages failed (non-fatal)"
    fi
fi

# ============================================================
# STAGE 6 — SSH Audit & Self-Healing
# ============================================================
if [[ -f "$SSOT/bootstrap/script/ssh_audit.sh" ]]; then
    log "Stage 6: SSH audit"
    bash "$SSOT/bootstrap/script/ssh_audit.sh" --fix 2>&1 | while IFS= read -r _line; do
        printf '  %s\n' "$_line"
    done
    ok "SSH audit complete"
else
    warn "ssh_audit.sh not found — skipping SSH setup"
fi

# ============================================================
# STAGE 7 — Verify Installation
# ============================================================
log "Stage 7: Verification"

_errors=0

# Check joe.sh exists and is valid
if [[ -f "$SSOT/joe.sh" ]] && bash -n "$SSOT/joe.sh" 2>/dev/null; then
    ok "joe.sh — exists and syntax valid"
else
    warn "joe.sh — missing or syntax error"
    _errors=$((_errors + 1))
fi

# Check .env has JOE_ENV
if grep -q "^export JOE_ENV=" "$HOME/.env" 2>/dev/null; then
    ok "~/.env — JOE_ENV configured"
else
    warn "~/.env — JOE_ENV not set"
    _errors=$((_errors + 1))
fi

# Check shell profile sources joe.sh
if [[ -L "$SHELL_RC" ]]; then
    _target="$(readlink "$SHELL_RC")"
    if grep -q "joe.sh" "$_target" 2>/dev/null; then
        ok "$SHELL_RC — sources joe.sh"
    else
        warn "$SHELL_RC — profile may not source joe.sh"
    fi
else
    if grep -q "joe.sh" "$SHELL_RC" 2>/dev/null; then
        ok "$SHELL_RC — sources joe.sh"
    else
        warn "$SHELL_RC — does not source joe.sh (may need manual fix)"
    fi
fi

# Check key modules exist
for _mod in "bootstrap/00-env.sh" "core/01-colors.sh" "core/aliases.sh" "core/3worlds.sh"; do
    if [[ -f "$SSOT/$_mod" ]]; then
        ok "$_mod — found"
    else
        warn "$_mod — missing"
        _errors=$((_errors + 1))
    fi
done

# Syntax-check all .sh files in core/ (quick scan)
if command -v bash >/dev/null 2>&1; then
    _syntax_fails=0
    for _f in "$SSOT"/core/*.sh "$SSOT"/functions/*.sh; do
        [[ -f "$_f" ]] || continue
        if ! bash -n "$_f" 2>/dev/null; then
            _syntax_fails=$((_syntax_fails + 1))
        fi
    done
    if [[ $_syntax_fails -eq 0 ]]; then
        ok "Syntax check — all core/*.sh and functions/*.sh pass"
    else
        warn "Syntax check — $_syntax_fails file(s) have errors"
    fi
fi

# ============================================================
# DONE — Summary
# ============================================================
printf '\n'
if [[ $_errors -eq 0 ]]; then
    printf '%s════════════════════════════════════════════════════%s\n' "${_BOLD}${_GREEN}" "${_RESET}"
    printf '%s  ✅ SSOT bootstrap complete!%s\n' "${_BOLD}${_GREEN}" "${_RESET}"
    printf '%s════════════════════════════════════════════════════%s\n' "${_BOLD}${_GREEN}" "${_RESET}"
else
    printf '%s════════════════════════════════════════════════════%s\n' "${_BOLD}${_YELLOW}" "${_RESET}"
    printf '%s  ⚠️  SSOT bootstrap complete with %d warning(s)%s\n' "${_BOLD}${_YELLOW}" "$_errors" "${_RESET}"
    printf '%s════════════════════════════════════════════════════%s\n' "${_BOLD}${_YELLOW}" "${_RESET}"
fi

printf '\n'
printf 'Next steps:\n'
printf '  1. %sRestart your shell:%s\n' "${_BOLD}" "${_RESET}"
if [[ "$JOE_ENV" == "TERMUX" ]]; then
    printf '       %sexec zsh%s\n' "${_BOLD}" "${_RESET}"
else
    printf '       %ssource %s%s\n' "${_BOLD}" "$SHELL_RC" "${_RESET}"
fi
printf '  2. (Optional) %sp10k configure%s — customize your prompt\n' "${_BOLD}" "${_RESET}"
printf '  3. %spf mom%s — seed AI API keys\n' "${_BOLD}" "${_RESET}"
printf '\n'
