# ============================================================
# .zsh-bash-compat.sh â€” Zsh -> Bash Compatibility Layer
# ============================================================
# Sourced by .zshrc BEFORE joe.sh to make bashscripts work in zsh.
# SSOT: ~/bashscripts/.zsh-bash-compat.sh
# ============================================================

# â”€â”€ 1. Bash-compatible shell options â”€â”€
setopt SH_WORD_SPLIT 2>/dev/null    # Word splitting like bash
setopt GLOB_SUBST 2>/dev/null       # Glob expansion like bash
setopt NULL_GLOB 2>/dev/null        # No error on empty globs
setopt KSH_ARRAYS 2>/dev/null       # 0-indexed arrays like bash
setopt NO_NOMATCH 2>/dev/null       # Don't error on unmatched globs

# â”€â”€ 2. BASH_SOURCE array shim for ZSH â”€â”€
# bash: BASH_SOURCE[0] inside a function = file where the function was defined.
# zsh:  equivalent is funcsourcetrace[1] = "file:lineno" of the function's
#       definition site. We initialize BASH_SOURCE[0] to the current file
#       as a fallback for top-level code (where funcsourcetrace is unset).
#       Functions should use ${funcsourcetrace[1]%%:*} (see entry.sh).
if [[ -n "${ZSH_VERSION:-}" ]]; then
    typeset -g -a BASH_SOURCE 2>/dev/null
    BASH_SOURCE=("${(%):-%x}")
fi

# â”€â”€ 3. Guard compdump function for compinit â”€â”€
# Prevents "compinit:484: compdump: function definition file not found"
if ! autoload +X -U compdump 2>/dev/null && ! typeset -f compdump &>/dev/null; then
    compdump() { return 0; }
fi

# â”€â”€ 4. Bash completion compatibility â”€â”€
# Only load bashcompinit if available; do NOT re-run compinit (OMZ already runs it)
if typeset -f compinit &>/dev/null || autoload +X -U compinit 2>/dev/null; then
    autoload -Uz bashcompinit 2>/dev/null && bashcompinit 2>/dev/null || true
fi

# â”€â”€ 5. complete() & compgen() shims â”€â”€
if ! command -v complete &>/dev/null && ! typeset -f complete &>/dev/null; then
    complete() { :; }
fi
if ! command -v compgen &>/dev/null && ! typeset -f compgen &>/dev/null; then
    compgen() { :; }
fi

# â”€â”€ 6. Unalias conflicts BEFORE bashscripts load â”€â”€
unalias sudo 2>/dev/null
unalias sd 2>/dev/null
unalias rc 2>/dev/null
unalias stc 2>/dev/null
unalias _ 2>/dev/null
unalias ls 2>/dev/null
unalias ll 2>/dev/null
unalias la 2>/dev/null

# â”€â”€ 7. Zsh-specific PATH helper â”€â”€
[[ -d /usr/local/bin ]] && export PATH="/usr/local/bin:$PATH"

# â”€â”€ 8. mapfile shim â”€â”€
if ! command -v mapfile &>/dev/null && ! typeset -f mapfile &>/dev/null; then
    mapfile() {
        local _opts=() _var=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -t) shift ;;
                -d) shift; shift ;;
                -n) shift; shift ;;
                -O) shift; shift ;;
                -s) shift; shift ;;
                *)  _var="$1"; shift ;;
            esac
        done
        eval "${_var}=(\"\${(@f)\"})"
    }
fi