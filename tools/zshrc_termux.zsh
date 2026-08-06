# ================================================================
# ~/.zshrc - JOE SSOT ZSH Config (Termux)
# MASTER: WSL | SSOT: ~/bashscripts/tools/zshrc_termux.zsh
# Deployed by: Fresh_termux_fullsetup_SSOT.sh (links to ~/.zshrc)
# Do NOT edit on Termux -- edit in WSL, Syncthing syncs it.
# ================================================================

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

# -- History substring search keybinds -------------------------
bindkey "^[[A" history-substring-search-up   2>/dev/null
bindkey "^[[B" history-substring-search-down 2>/dev/null