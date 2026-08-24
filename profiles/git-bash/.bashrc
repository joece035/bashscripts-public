# ~/.bashrc: executed by bash(1) for non-login shells.

[[ -f "$HOME/bashscripts/.bash_helper" ]] && source "$HOME/bashscripts/.bash_helper"
# ── 1. CORE BASH CONFIG ──
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ── 2. BASH LINE EDITOR (Source only, no attach yet) ──
if [[ $- == *i* && -f ~/.local/share/blesh/ble.sh ]]; then
    [[ ${BLE_VERSION-} ]] || source ~/.local/share/blesh/ble.sh --attach=none
fi

# ── 3. NVM & COMPLETIONS (MUST come BEFORE .env) ──
# .env reads NVM_DIR to find node path — needs NVM init first
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use default >/dev/null 2>&1 || true

# ── 4. ENVIRONMENT & PATHS ──
. "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/lib/openclaw/bin:$PATH"
export SSOT="$HOME/bashscripts"
export MY_DEVICE=${WSL:-$JOE_ENV}
[ -f ~/.env ] && source ~/.env

# ── 5. ALIASES & COMPLETIONS ──
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# ── 6. PERSONAL COMMAND CENTER (JOE) ──
# Source joe.sh; suppress all errors so any function-level bugs
# don't kill the shell (defensive — not a fix, just safety net)
# CRLF guard: ถ้า joe.sh ถูกบันทึกเป็น CRLF (จาก Windows/Acode-X) bash จะ
# parse ไม่ผ่าน → แปลงกลับเป็น LF ก่อน source (joe.sh มี self-heal ข้างในด้วย)
if [ -f ~/bashscripts/joe.sh ] && grep -qU $'\r' ~/bashscripts/joe.sh 2>/dev/null; then
    sed -i 's/\r$//' ~/bashscripts/joe.sh
    echo "⚠️  CRLF→LF: joe.sh (auto-fixed)"
fi
[ -f ~/bashscripts/joe.sh ] && . ~/bashscripts/joe.sh 2>/dev/null

# ── 6. STARSHIP ──
# if [[ $- == *i* && -z "$STARSHIP_LOADED" ]]; then
#     eval "$(starship init bash)"
#     STARSHIP_LOADED=1
# fi

# ── 8. ATTACH BLE.SH ──
if [[ $- == *i* && ${BLE_VERSION-} && -z "$BLE_ATTACHED" ]]; then
    export BLE_ATTACHED=1
    ble-attach
fi

# ── 9. FINAL SETTINGS ──

alias ktmux="tmux kill-server"

# OpenClaw Completion
[ -f "/home/usercivenz/.openclaw-2/completions/openclaw.bash" ] && source "/home/usercivenz/.openclaw-2/completions/openclaw.bash"

# opencode
export PATH=/home/usercivenz/.opencode/bin:$PATH


# Added by Antigravity CLI installer
export PATH="/home/usercivenz/.local/bin:$PATH"

# pnpm
export PNPM_HOME="/home/usercivenz/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"


export TERM=xterm-256color
