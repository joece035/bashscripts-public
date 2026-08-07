#!/usr/bin/env zsh
for d in /usr/share/zsh/**/*(/N); do
    if [[ -f "$d/compinit" ]]; then
        echo "FOUND COMPINIT IN: $d"
    fi
    if [[ -f "$d/bashcompinit" ]]; then
        echo "FOUND BASHCOMPINIT IN: $d"
    fi
done