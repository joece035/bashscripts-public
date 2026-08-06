# ============================================================
# .zsh-bash-compat.sh — Zsh -> Bash Compatibility Layer
# ============================================================
# Sourced by .zshrc BEFORE joe.sh to make bashscripts work in zsh.
# SSOT: ~/bashscripts/.zsh-bash-compat.sh
# ============================================================

# ── 1. Bash-compatible shell options ──
setopt SH_WORD_SPLIT 2>/dev/null    # Word splitting like bash
setopt GLOB_SUBST 2>/dev/null       # Glob expansion like bash
setopt NULL_GLOB 2>/dev/null        # No error on empty globs
setopt NO_NOMATCH 2>/dev/null
setopt KSH_ARRAYS 2>/dev/null       # 0-indexed arrays like bash

# ── 2. BASH_SOURCE array shim for ZSH ──
if [[ -n "${ZSH_VERSION:-}" ]]; then
    typeset -g -a BASH_SOURCE
    BASH_SOURCE=("${(%):-%x}")
fi

# ── 3. Bash completion system ──
autoload -Uz compinit 2>/dev/null && compinit -u 2>/dev/null
autoload -Uz bashcompinit 2>/dev/null && bashcompinit 2>/dev/null

# ── 4. complete() shim for bash scripts ──
if ! command -v complete &>/dev/null && ! typeset -f complete &>/dev/null; then
    complete() { :; }
fi
if ! command -v compgen &>/dev/null && ! typeset -f compgen &>/dev/null; then
    compgen() { :; }
fi

# ── 5. Unalias conflicts BEFORE bashscripts load ──
unalias sudo 2>/dev/null
unalias sd 2>/dev/null
unalias rc 2>/dev/null
unalias stc 2>/dev/null
unalias _ 2>/dev/null
unalias ls 2>/dev/null
unalias ll 2>/dev/null
unalias la 2>/dev/null

# ── 6. Zsh-specific PATH helper ──
[[ -d /usr/local/bin ]] && path=("/usr/local/bin" $path)

# ── 7. mapfile shim ──
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
