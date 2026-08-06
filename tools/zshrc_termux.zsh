# ================================================================
# ~/.zshrc - JOE SSOT ZSH Config (Termux)
# MASTER: WSL | SSOT: ~/bashscripts/tools/zshrc_termux.zsh
# Deployed by: Fresh_termux_fullsetup_SSOT.sh (links to ~/.zshrc)
# Do NOT edit on Termux -- edit in WSL, Syncthing syncs it.
# ================================================================

# -- Termux / Local PATH ---------------------------------------
[[ -d "/data/data/com.termux/files/usr/bin" ]] && PATH="/data/data/com.termux/files/usr/bin:$PATH"
PATH="/usr/bin:/bin:$HOME/.local/bin:$PATH"
export PATH

# -- Powerlevel10k instant prompt (must be near top) -----------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -- Oh My Zsh -------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    autoupdate
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# -- ZSH/Bash compat layer (BEFORE joe.sh) ---------------------
SSOT_PATH="${SSOT:-$HOME/bashscripts}"
[[ -f "$SSOT_PATH/.zsh-bash-compat.sh" ]] && source "$SSOT_PATH/.zsh-bash-compat.sh"

# -- JOE SSOT single entry point --------------------------------
# joe.sh: JOE_ENV detection -> 00-env.sh -> 01-colors.sh -> functions
[[ -f "$SSOT_PATH/joe.sh" ]] && source "$SSOT_PATH/joe.sh"

# -- Powerlevel10k config --------------------------------------
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# -- Safe UP/DOWN keybindings (prevent missing function file errors) --
if ! autoload +X -U up-line-or-beginning-search 2>/dev/null; then
    up-line-or-beginning-search() { zle up-line-or-history; }
    zle -N up-line-or-beginning-search 2>/dev/null
fi
if ! autoload +X -U down-line-or-beginning-search 2>/dev/null; then
    down-line-or-beginning-search() { zle down-line-or-history; }
    zle -N down-line-or-beginning-search 2>/dev/null
fi

if zle -la 2>/dev/null | grep -q history-substring-search; then
    bindkey '^[[A' history-substring-search-up   2>/dev/null
    bindkey '^[[B' history-substring-search-down 2>/dev/null
    bindkey "$terminfo[kcuu1]" history-substring-search-up   2>/dev/null
    bindkey "$terminfo[kcud1]" history-substring-search-down 2>/dev/null
else
    bindkey '^[[A' up-line-or-history   2>/dev/null
    bindkey '^[[B' down-line-or-history 2>/dev/null
fi

# -- Powerlevel10k finalize (required for instant prompt) ------
(( ! ${+functions[p10k]} )) || p10k finalize