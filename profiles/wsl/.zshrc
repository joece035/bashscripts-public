# ================================================================
# ~/.zshrc - JOE SSOT ZSH Config (WSL)
# SSOT: ~/bashscripts/profiles/wsl/.zshrc
# Linked to: ~/.zshrc
# ================================================================
[[ -f "$HOME/bashscripts/.bash_helper" ]] && source "$HOME/bashscripts/.bash_helper"

# -- Terminal type (micro/TUI needs this) -----------------------
export TERM="${TERM:-xterm-256color}"
export COLORTERM="truecolor"

# -- Shell Options (Prevent glob errors & duplicate fpath) ------
setopt NO_NOMATCH 2>/dev/null || true
setopt NULL_GLOB 2>/dev/null || true
typeset -U fpath path PATH 2>/dev/null || true

# -- Powerlevel10k instant prompt (quiet output warning) -------
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -- NVM (Node Version Manager - MUST come BEFORE .env) --------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use default >/dev/null 2>&1 || true

# -- Path Setup ------------------------------------------------
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$HOME/.local/lib/openclaw/bin:$HOME/.opencode/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export SSOT="$HOME/bashscripts"
export MY_DEVICE="${WSL:-WSL}"

# -- Oh My Zsh Flags -------------------------------------------
export DISABLE_LS_COLORS="true"
export ZSH_DISABLE_COMPFIX="true"

# -- Clear old shell function conflicts for OMZ spectrum -------
unfunction color 2>/dev/null || true
unset color 2>/dev/null || true

# -- Oh My Zsh (Source ONCE per session) -----------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
)

if [[ -z "${_OMZ_SOURCED:-}" ]]; then
    export _OMZ_SOURCED=1
    [[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
fi

# -- ZSH/Bash compat layer (BEFORE joe.sh) ---------------------
[[ -f "$HOME/.env" ]] && source "$HOME/.env"
SSOT="${SSOT:-$HOME/bashscripts}"
[[ -f "$SSOT/.zsh-bash-compat.sh" ]] && source "$SSOT/.zsh-bash-compat.sh"
[[ -f "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"

# -- JOE SSOT single entry point --------------------------------
# joe.sh: JOE_ENV detection -> 00-env.sh -> 01-colors.sh -> functions
[[ -f "$SSOT/joe.sh" ]] && source "$SSOT/joe.sh"

# -- Powerlevel10k config --------------------------------------
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# -- Safe UP/DOWN keybindings ----------------------------------
if ! autoload +X -U up-line-or-beginning-search 2>/dev/null; then
    up-line-or-beginning-search() { zle up-line-or-history; }
    zle -N up-line-or-beginning-search 2>/dev/null
fi
if ! autoload +X -U down-line-or-beginning-search 2>/dev/null; then
    down-line-or-beginning-search() { zle down-line-or-history; }
    zle -N down-line-or-beginning-search 2>/dev/null
fi

if zle -la 2>/dev/null | grep -q history-substring-search; then
    bindkey "^[[A" history-substring-search-up   2>/dev/null
    bindkey "^[[B" history-substring-search-down 2>/dev/null
    bindkey "$terminfo[kcuu1]" history-substring-search-up   2>/dev/null
    bindkey "$terminfo[kcud1]" history-substring-search-down 2>/dev/null
else
    bindkey "^[[A" up-line-or-history   2>/dev/null
    bindkey "^[[B" down-line-or-history 2>/dev/null
fi

GITSTATUS_LOG_LEVEL=DEBUG

# -- Powerlevel10k finalize ------------------------------------
(( ! ${+functions[p10k]} )) || p10k finalize

# -- Aliases & Integrations ------------------------------------
alias ktmux="tmux kill-server"

# OpenClaw Completion
[ -f "$HOME/.openclaw-2/completions/openclaw.bash" ] && source "$HOME/.openclaw-2/completions/openclaw.bash" 2>/dev/null || true

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# Micro editor wrapper
micro() {
    if [[ -z "$TERM" || "$TERM" == "dumb" ]]; then
        export TERM="xterm-256color"
        export COLORTERM="truecolor"
    fi
    if ! [ -t 0 ] || ! [ -t 1 ]; then
        if [[ -c /dev/tty ]]; then
            TERM="${TERM:-xterm-256color}" command micro "$@" </dev/tty >/dev/tty
            return $?
        else
            printf "\033[31mERROR: micro requires an interactive TTY\033[0m\n"
            return 1
        fi
    fi
    command printf "\033[?1049l" 2>/dev/null
    command printf "\033[0m" 2>/dev/null
    command printf "\033[?25h" 2>/dev/null
    command printf "\033[2J\033[H" 2>/dev/null
    TERM="${TERM:-xterm-256color}" command micro "$@"
    local ret=$?
    command printf "\033[?1049l" 2>/dev/null
    command printf "\033[0m" 2>/dev/null
    return $ret
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
