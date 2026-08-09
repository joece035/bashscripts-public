#!/bin/bash
THEME_FILE="$HOME/bashscripts/theme.sh"

cat > /tmp/theme_zsh.txt << 'EOF'
# ── Shell-aware prompt registration ──
# Bash uses PROMPT_COMMAND; Zsh uses Oh My Zsh / Powerlevel10k prompt
if [[ -z "${ZSH_VERSION:-}" ]]; then
    PROMPT_COMMAND=_set_prompt
fi
EOF

START=$(grep -n "Shell-aware prompt registration" "$THEME_FILE" | cut -d: -f1)
END=$(grep -n "Show Fastfetch" "$THEME_FILE" | cut -d: -f1)

head -n $((START-2)) "$THEME_FILE" > /tmp/theme_new.sh
cat /tmp/theme_zsh.txt >> /tmp/theme_new.sh
echo "" >> /tmp/theme_new.sh
tail -n +$((END-1)) "$THEME_FILE" >> /tmp/theme_new.sh
cp /tmp/theme_new.sh "$THEME_FILE"
echo "theme.sh patched!"