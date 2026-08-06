#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Fresh_termux_fullsetup_SSOT.sh
#  ───────────────────────────────────────────────────────────
#  ONE-SHOT bootstrap for a FRESH Termux install.
#  Sets up EVERYTHING the SSOT (~/bashscripts) ecosystem needs
#  and switches the login shell to ZSH.
#
#  Run on the phone:
#      bash Fresh_termux_fullsetup_SSOT.sh
#
#  Idempotent: safe to re-run; skips steps already done.
#
#  NOTE: This script runs BEFORE 01-colors.sh exists, so it
#  cannot use c()/cn(). Colors via `tput` only (no inline \e[).
# ============================================================

set -euo pipefail 2>/dev/null || setopt PIPE_FAIL 2>/dev/null

# Disable history expansion (!) — safe for zsh if the script
# gets sourced or if chsh changes the shell mid-run (Termux quirk).
set +H 2>/dev/null || true

# ── Minimal color helpers (tput — portable, no inline ANSI) ──
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    _B="$(tput bold)"; _R="$(tput sgr0)"
    _G="$(tput setaf 2)"; _Y="$(tput setaf 3)"
    _R_C="$(tput setaf 1)"; _C="$(tput setaf 6)"
else
    _B=""; _R=""; _G=""; _Y=""; _R_C=""; _C=""
fi
log()  { printf '%s==>%s %s\n' "$_B$_C" "$_R" "$*"; }
ok()   { printf '   %s✓%s %s\n' "$_G" "$_R" "$*"; }
warn() { printf '   %s!%s %s\n' "$_Y" "$_R" "$*" >&2; }
die()  { printf '%s✗%s %s\n' "$_R_C$_B" "$_R" "$*" >&2; exit 1; }

# ── Paths (canonical — match joe.sh Step 2 TERMUX branch) ──
TERMUX_HOME="/data/data/com.termux/files/home"
SSOT_DIR="$TERMUX_HOME/bashscripts"
ZSH_CUSTOM="${ZSH_CUSTOM:-$TERMUX_HOME/.oh-my-zsh/custom}"

# ============================================================
# STAGE 0 — Preflight
# ============================================================
log "Stage 0: Preflight"
[[ -d /data/data/com.termux ]] || die "Not running inside Termux (no /data/data/com.termux)."
command -v pkg >/dev/null 2>&1 || die "pkg manager not found."
ok "Termux detected."

# ============================================================
# STAGE 1 — Storage access (so Syncthing/SDCARD paths work)
# ============================================================
log "Stage 1: Storage access"
if [[ ! -d /storage/emulated/0 ]]; then
    termux-setup-storage </dev/null || die "termux-setup-storage failed (approve the prompt)."
    ok "Storage permission requested."
else
    ok "Storage already accessible."
fi

# ============================================================
# STAGE 1.5 — Clear stale apt/dpkg locks (Termux apt can hang
#   for 10+ min if a previous pkg install was interrupted)
#   NOTE: wrapped in set +e — fuser/psmisc may not be installed
#   yet on a fresh Termux, so we use lsof fallback or just
#   force-remove the locks (safe on a fresh install).
# ============================================================
log "Stage 1.5: Check for stale apt locks"
set +e
DPKG_DIR="/data/data/com.termux/files/usr/var/lib/dpkg"
APT_ARCHIVES="/data/data/com.termux/files/usr/var/cache/apt/archives"

# Try to find a process holding the lock (fuser → lsof → none)
_lock_pid=""
if command -v fuser >/dev/null 2>&1; then
    _lock_pid="$(fuser "$DPKG_DIR/lock-frontend" 2>/dev/null | tr -d ' ')"
elif command -v lsof >/dev/null 2>&1; then
    _lock_pid="$(lsof -t "$DPKG_DIR/lock-frontend" 2>/dev/null | head -1 | tr -d ' ')"
fi

if [[ -n "$_lock_pid" ]]; then
    _etime="$(ps -o etimes= -p "$_lock_pid" 2>/dev/null | tr -d ' ')"
    if [[ -n "$_etime" ]] && [[ "$_etime" -gt 120 ]]; then
        warn "Stale apt lock held by PID $_lock_pid for ${_etime}s — killing."
        kill -9 "$_lock_pid" 2>/dev/null
        pkill -9 -x apt 2>/dev/null
        pkill -9 -x dpkg 2>/dev/null
        sleep 1
    else
        log "apt lock held by PID $_lock_pid (${_etime:-0}s) — waiting up to 60s..."
        _wait=0
        while [[ $_wait -lt 60 ]]; do
            sleep 2; _wait=$((_wait+2))
            _still=""
            if command -v fuser >/dev/null 2>&1; then
                _still="$(fuser "$DPKG_DIR/lock-frontend" 2>/dev/null | tr -d ' ')"
            elif command -v lsof >/dev/null 2>&1; then
                _still="$(lsof -t "$DPKG_DIR/lock-frontend" 2>/dev/null | head -1 | tr -d ' ')"
            fi
            [[ -z "$_still" ]] && break
        done
        if [[ -n "$_still" ]]; then
            warn "apt lock still held after 60s — force-clearing."
        fi
    fi
fi

# Force-remove stale lock files (safe on fresh install — no real
# apt process should be running during bootstrap)
rm -f "$DPKG_DIR/lock-frontend" "$DPKG_DIR/lock" "$APT_ARCHIVES/lock" 2>/dev/null
# Repair any interrupted dpkg state
dpkg --configure -a 2>/dev/null
ok "Locks cleared, dpkg state consistent."
set -e

# ============================================================
# STAGE 2 — Update base system
#   Retry with --fix-missing on 404 (stale mirror).
#   If it still fails, suggest termux-change-repo.
# ============================================================
log "Stage 2: Update base system"
set +e
pkg update -y 2>&1
pkg upgrade -y 2>&1
_rc=$?
set -e

if [[ $_rc -ne 0 ]]; then
    warn "pkg upgrade failed (rc=$_rc). Retrying with --fix-missing..."
    set +e
    apt-get update -y 2>&1
    apt-get upgrade -y --fix-missing 2>&1
    _rc2=$?
    set -e
    if [[ $_rc2 -ne 0 ]]; then
        printf '\n%s*** Mirror may be stale (404 errors). ***%s\n' "$_Y" "$_R" >&2
        printf 'Run this to switch mirror, then re-run the script:\n' >&2
        printf '    %stermux-change-repo%s\n' "$_B" "$_R" >&2
        printf '    bash Fresh_termux_fullsetup_SSOT.sh\n\n' >&2
        die "Base update failed — run termux-change-repo first."
    fi
fi
ok "Packages updated."

# ============================================================
# STAGE 3 — Install SSOT dependencies
#   Sourced from actual `command -v` checks across the repo:
#   curl (3worlds, syncctl), jq (syncctl), rsync (fm), python3
#   (block/utils, syncctl fallback), git (theme), ssh/scp (3worlds),
#   syncthing (3worlds), tailscale (3worlds, status), node (openclaw).
#
#   NOTE on Termux packages:
#   - sed/grep are GNU by default (no gnu-sed/gnugrep names)
#   - tailscale requires root-repo — installed separately below
#   - psmisc (fuser) may not exist — installed with || true
# ============================================================
log "Stage 3: Install SSOT dependencies"
PKGS=(
    zsh git curl wget jq openssh rsync
    python python-pip nodejs
    vim neovim fzf ripgrep bat htop tmux tree zip unzip
    lsd termux-api
    termux-tools coreutils findutils sed grep psmisc
)
pkg install -y "${PKGS[@]}" && ok "Core packages installed." \
    || { warn "Some core packages failed — retrying with --fix-missing..."; \
         apt-get install -y --fix-missing "${PKGS[@]}" 2>&1 && ok "Core packages installed (retry)." \
         || warn "Some packages still failed (check above)."; }

# tailscale + syncthing need extra repos — install separately, non-fatal
for _extra in tailscale syncthing; do
    if ! command -v "$_extra" >/dev/null 2>&1; then
        pkg install -y "$_extra" 2>/dev/null \
            && ok "$_extra installed." \
            || warn "$_extra not available — install manually later (may need root-repo)."
    else
        ok "$_extra already installed."
    fi
done

# ============================================================
# STAGE 4 — ZSH as default login shell
# ============================================================
log "Stage 4: Set ZSH as default shell"
ZSH_BIN="$(command -v zsh)"
if [[ -n "$ZSH_BIN" ]]; then
    if [[ "$SHELL" != *zsh* ]]; then
        chsh -s "$ZSH_BIN" || warn "chsh failed — run manually: chsh -s $ZSH_BIN"
        ok "Default shell → zsh"
    else
        ok "ZSH already default shell."
    fi
else
    die "zsh not installed after Stage 3."
fi

# ============================================================
# STAGE 5 — Oh-My-Zsh (non-interactive)
# ============================================================
log "Stage 5: Oh-My-Zsh"
export RUNZSH=no KEEP_ZSHRC=yes CHSH=no
if [[ ! -d "$TERMUX_HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh-My-Zsh installed."
else
    ok "Oh-My-Zsh already present."
fi

# ============================================================
# STAGE 6 — ZSH plugins + powerlevel10k theme
# ============================================================
log "Stage 6: ZSH plugins + powerlevel10k"
mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"

clone_if_absent() {
    local url="$1" dest="$2"
    if [[ ! -d "$dest" ]]; then
        git clone --depth=1 "$url" "$dest" && ok "cloned: $(basename "$dest")"
    else
        ok "exists: $(basename "$dest")"
    fi
}

clone_if_absent https://github.com/romkatv/powerlevel10k.git        "$ZSH_CUSTOM/themes/powerlevel10k"
clone_if_absent https://github.com/TamCore/autoupdate-oh-my-zsh-plugins "$ZSH_CUSTOM/plugins/autoupdate"
clone_if_absent https://github.com/marlonrichert/zsh-autocomplete "$ZSH_CUSTOM/plugins/zsh-autocomplete"
clone_if_absent https://github.com/zsh-users/zsh-autosuggestions   "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_absent https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_absent https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
# ============================================================
# STAGE 7 — Check SSOT repo (~/bashscripts)
#   If Syncthing already synced ~/bashscripts, skip git clone.
# ============================================================
log "Stage 7: Check SSOT repo"

if [[ -d "$SSOT_DIR" && -f "$SSOT_DIR/joe.sh" ]]; then
    ok "SSOT repo already present at $SSOT_DIR (via Syncthing)"
else
    SSH_KEY="$TERMUX_HOME/.ssh/id_ed25519"
    if [[ ! -f "$SSH_KEY" ]]; then
        log "  Generating SSH key..."
        ssh-keygen -t ed25519 -C "termux@$(hostname)" -f "$SSH_KEY" -N "" 2>&1
        ok "SSH key generated."
    fi

    if command -v ssh-agent >/dev/null 2>&1; then
        _agent_out="$(ssh-agent -s 2>/dev/null)" || true
        if [[ -n "$_agent_out" ]]; then
            eval "$_agent_out" >/dev/null 2>&1
            ssh-add "$SSH_KEY" 2>/dev/null || true
            ok "SSH agent running."
        fi
    fi

    if ! ssh -T git@github.com -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 2>&1 | grep -q "successfully authenticated"; then
        warn "GitHub SSH key not registered — continuing via Syncthing setup..."
    fi

    if [[ ! -d "$SSOT_DIR/.git" ]]; then
        git clone git@github.com:sitthawat035/bashscripts.git "$SSOT_DIR" 2>/dev/null \
            || warn "Git clone skipped — relies on Syncthing sync"
    fi
fi

# ============================================================
# STAGE 8 — ~/.env  (JOE_ENV pin — joe.sh Step 0 reads this)
# ============================================================
log "Stage 8: Write ~/.env"
ENV_FILE="$TERMUX_HOME/.env"
if ! grep -q '^export JOE_ENV=' "$ENV_FILE" 2>/dev/null; then
    cat >> "$ENV_FILE" <<'EOF'
# Set by Fresh_termux_fullsetup_SSOT.sh
export JOE_ENV="TERMUX"
EOF
    ok "~/.env: JOE_ENV=TERMUX pinned."
else
    ok "~/.env already has JOE_ENV."
fi

# ============================================================
# STAGE 9 -- Wire ~/.zshrc to SSOT zshrc_termux.zsh (symlink)
#   SSOT template lives in bashscripts/tools/zshrc_termux.zsh
#   which is synced from WSL master via Syncthing.
#   On Termux: ~/.zshrc is a symlink -> SSOT (read-only on device).
# ============================================================
log "Stage 9: Wire ~/.zshrc -> zshrc_termux.zsh (SSOT symlink)"
ZSHRC_DEST="$TERMUX_HOME/.zshrc"
ZSHRC_SRC="$SSOT_DIR/tools/zshrc_termux.zsh"

if [[ ! -f "$ZSHRC_SRC" ]]; then
    warn "zshrc_termux.zsh not found at $ZSHRC_SRC"
    warn "Syncthing may not have synced yet -- ~/.zshrc will be created after sync"
else
    # Backup existing .zshrc if NOT already our symlink
    if [[ -f "$ZSHRC_DEST" && ! -L "$ZSHRC_DEST" ]]; then
        mv "$ZSHRC_DEST" "${ZSHRC_DEST}.bak.$(date +%s)"
        warn "Backed up existing ~/.zshrc"
    fi
    ln -sf "$ZSHRC_SRC" "$ZSHRC_DEST"
    ok "~/.zshrc -> $ZSHRC_SRC (SSOT symlink)"
fi



# ============================================================
# STAGE 10 — termux-style (optional theme picker)
# ============================================================
log "Stage 10: termux-style (optional)"
TS_DIR="$TERMUX_HOME/termux-style"
if [[ ! -d "$TS_DIR" ]]; then
    git clone https://github.com/adi1090x/termux-style "$TS_DIR" && (cd "$TS_DIR" && ./install) \
        || warn "termux-style install failed (non-fatal)."
    ok "termux-style installed — run 'termux-style' to pick a theme."
else
    ok "termux-style already installed."
fi

# ============================================================
# STAGE 11 — SSH server (for 3worlds tm/tw SSH helpers)
# ============================================================
log "Stage 11: SSH daemon"
if command -v sshd >/dev/null 2>&1; then
    # Set a password for the Termux user (needed for SSH from other nodes)
    if [[ ! -f "$TERMUX_HOME/.ssh/authorized_keys" ]]; then
        mkdir -p "$TERMUX_HOME/.ssh"
        chmod 700 "$TERMUX_HOME/.ssh"
        touch "$TERMUX_HOME/.ssh/authorized_keys"
        chmod 600 "$TERMUX_HOME/.ssh/authorized_keys"
    fi
    passwd -e 2>/dev/null || warn "Set a password manually: passwd"
    ok "SSH ready — start with 'sshd' (joe.sh auto-starts it on boot)."
fi

# ============================================================
# DONE — print summary (printf, NOT heredoc — avoids zsh
#   history-expansion issues when chsh switches shell mid-run)
# ============================================================
printf '\n'
printf '%s════════════════════════════════════════════════════%s\n' "$_B$_G" "$_R"
printf '%s  SSOT bootstrap complete.%s\n' "$_B$_G" "$_R"
printf '%s════════════════════════════════════════════════════%s\n' "$_B$_G" "$_R"
printf '\n'
printf 'Next steps:\n'
printf '  1. %schsh -s zsh%s  (if Stage 4 warned) then restart Termux\n' "$_B" "$_R"
printf '  2. %sexec zsh%s     (or close & reopen the session)\n' "$_B" "$_R"
printf '  3. On first zsh launch, powerlevel10k config wizard runs -- answer it.\n'
printf '  4. %sIMPORTANT%s: reinstalling Termux changed your Syncthing\n' "$_Y" "$_R"
printf '     device ID. From a node that has Syncthing online, run:\n'
printf '        %sst-register-all%s\n' "$_B" "$_R"
printf '     so the mesh re-learns this phone new ID.\n'
printf '  5. (Optional) %stailscale up%s to rejoin the tailnet.\n' "$_B" "$_R"
printf '\n'




