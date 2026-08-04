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

set -euo pipefail

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
# ============================================================
log "Stage 2: Update base system"
pkg update -y && pkg upgrade -y
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
pkg install -y "${PKGS[@]}" && ok "Core packages installed." || warn "Some core packages failed (check above)."

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

# ============================================================
# STAGE 7 — Clone SSOT repo (~/bashscripts)
# ============================================================
log "Stage 7: Clone SSOT repo"
if [[ ! -d "$SSOT_DIR/.git" ]]; then
    git clone https://github.com/sitthawat035/bashscripts.git "$SSOT_DIR" \
        || die "Clone failed — check network or repo access."
    ok "SSOT cloned to $SSOT_DIR"
else
    ok "SSOT already at $SSOT_DIR (pulling)."
    git -C "$SSOT_DIR" pull --ff-only || warn "pull failed — check manually."
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
# STAGE 9 — Wire ~/.zshrc to source joe.sh (the SSOT booster)
#   joe.sh is the ONLY entry point (per AGENT.md load order).
#   It auto-detects TERMUX, sources 00-env.sh → 01-colors.sh → ...
# ============================================================
log "Stage 9: Wire ~/.zshrc → joe.sh"
ZSHRC="$TERMUX_HOME/.zshrc"
touch "$ZSHRC"

# Set ZSH_THEME to powerlevel10k (only if user hasn't customized)
if grep -q '^ZSH_THEME=' "$ZSHRC"; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC"
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
fi

# Ensure plugins line includes our extras
if ! grep -q '^plugins=\(' "$ZSHRC"; then
    cat >> "$ZSHRC" <<'EOF'
plugins=(git autoupdate zsh-autocomplete zsh-autosuggestions zsh-syntax-highlighting)
EOF
fi

# Source joe.sh exactly once (idempotent guard block)
if ! grep -q 'Fresh_termux_fullsetup_SSOT' "$ZSHRC"; then
    cat >> "$ZSHRC" <<'EOF'

# ── Fresh_termux_fullsetup_SSOT — SSOT booster (single entry point) ──
# joe.sh detects JOE_ENV, then sources 00-env.sh → 01-colors.sh → ...
if [[ -f "$HOME/bashscripts/joe.sh" ]]; then
    source "$HOME/bashscripts/joe.sh"
fi
EOF
    ok "~/.zshrc wired to source joe.sh."
else
    ok "~/.zshrc already wired."
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
# DONE
# ============================================================
cat <<EOF

${_B}${_G}════════════════════════════════════════════════════${_R}
${_B}${_G}  SSOT bootstrap complete.${_R}
${_B}${_G}════════════════════════════════════════════════════${_R}

Next steps:
  1. ${_B}chsh -s zsh${_R}  (if Stage 4 warned) then restart Termux
  2. ${_B}exec zsh${_R}     (or close & reopen the session)
  3. On first zsh launch, powerlevel10k config wizard runs — answer it.
  4. ${_Y}IMPORTANT${_R}: reinstalling Termux changed your Syncthing
     device ID. From a node that has Syncthing online, run:
        ${_B}st-register-all${_R}
     so the mesh re-learns this phone's new ID.
  5. (Optional) ${_B}tailscale up${_R} to rejoin the tailnet.

EOF




