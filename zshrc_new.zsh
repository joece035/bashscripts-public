# ~/.zshrc - Mission Control Loader
# LOADER ONLY. No hardcoding. All logic in ~/bashscripts/

export PATH="/data/data/com.termux/files/usr/bin:$HOME/.openclaw-android/node/bin:$HOME/.local/bin:$PATH"
export TMPDIR="${PREFIX:-/tmp}/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export OA_GLIBC=1
export CONTAINER=1

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="random"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# 1. Variables (Single Source of Truth)
[ -f ~/bashscripts/.bashjoe ] && source ~/bashscripts/.bashjoe
# 2. SSH and 3-Worlds (tm, tw, push, pull, world)
[ -f ~/bashscripts/3worlds.sh ] && source ~/bashscripts/3worlds.sh
# 3. Universal File Manager
[ -f ~/bashscripts/bash-manager.sh ] && source ~/bashscripts/bash-manager.sh
# 4. Zsh-specific commands (hmgw, opdb, tsc, recon)
[ -f ~/bashscripts/zsh-manager.zsh ] && source ~/bashscripts/zsh-manager.zsh

alias h="fm help"
alias reload="source ~/.zshrc"
alias pp="reload"
alias fmr="fm help"
alias fmoff="fm learn off"
alias fmon="fm learn on"
alias ktmux="tmux kill-server"

[ -x "$(command -v fastfetch)" ] && fastfetch --config termux
