#!/bin/bash
# ======================================================
# 🎨 JOE'S TERMINAL THEME & PROMPT (WSL Ubuntu Edition)
# ======================================================

# 1. Colors loaded from 01-colors.sh via joe.sh (no redefinition needed)

# 2. ฟังก์ชันตรวจสอบ Git Branch แบบไม่หน่วงเครื่อง (Lightweight Git Status)
_git_prompt() {
    if command -v git >/dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null)
        if [ -n "$branch" ]; then
            # ตรวจสอบว่ามีข้อมูลค้างยังไม่ได้ commit หรือไม่
            if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                c 226 b " 🌿 ${branch}*"
            else
                c 82 b " 🌿 ${branch}"
            fi
        fi
    fi
}

# 3. ฟังก์ชันเช็คสถานะคำสั่งล่าสุด (Exit Code Status)
_exit_status() {
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        c 10 b "success ^!!    "
    else
        c 9 b "failed !!    "
    fi
}

# 4. ประกอบร่างเป็น Dynamic PS1 (Prompt)
# [ Exit Code ] [ ENV ] [ User@Host ] [ Path ] [ Git ]
# ──>
# V4 SSOT: use _c/_b/_r helpers (raw escape emitters from 01-colors.sh).
# PS1 needs literal escape codes wrapped in \[ \] (bash non-printing marker).
# c()/cn() output text + escape — use them for plain text segments; use
# _c/_b/_r directly for PS1 where bash will re-interpret \u, \w, etc.
_set_prompt() {
    local last_status="$(_exit_status)" # ต้องเก็บค่าก่อนคำสั่งอื่นจะทำงาน
    local env_tag="\[$(_c 141)\]\[${JOE_ENV:-$MY_DEVICE}\]\[$(_r)\]"
    local user_host="\[$(_c 51)\]\u\[$(_r)\]@\[$(_c 244)\]\h\[$(_r)\]"
    local current_dir="\[$(_c 226)\]\w\[$(_r)\]"
    local git_info="$(_git_prompt)"
    local arrow="\[$(_b)\]──>\[$(_r)\]"

    # กำหนดค่า PS1 สำหรับ Bash
    PS1="\n${last_status} ${env_tag} ${user_host} in ${current_dir}${git_info}\n${arrow} "
}

# สั่งให้ Bash รันฟังก์ชันนี้ทุกครั้งก่อนแสดง Prompt
if [[ -z "${ZSH_VERSION:-}" ]]; then PROMPT_COMMAND=_set_prompt; fi

# 5. Show Fastfetch (only in interactive WSL shells with logo)
if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
    if [ "$JOE_ENV" = "WSL" ]; then
        clear
        fastfetch --logo ubuntu
    fi
fi


draw_() {
   
   printf "%*s" "$2" "" | sed "s/ /$1/g"  
}
alias d_='draw_'

printf "%s" "

"




