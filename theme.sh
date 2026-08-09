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
    local env_tag="\[$(_c 141)\]\[${JOE_ENV:-WSL}\]\[$(_r)\]"
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

color_test() {
    case "$1" in
        a)
            rc1 b "test 1";
            rc1 b "test 2";
            rc1 b "test 3";
            rc1 b "test 4";
            rc1 b "test 5";
            rc1 b "test 6";
            rc1 b "test 7";
            rc1 b "test 8";
            rc1 b "test 9";
            rc1 b "test 10";
            rc1 b "test 11";
            rc1 b "test 12";
            rc1 b "test 13";
            rc1 b "test 14";
            rc1 b "test 15";
            rc1 b "test 16";
            rc1 b "test 17";
            rc1 b "test 18";
            rc1 b "test 19";
            rc1 b "test 20"
        ;;
        b)
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬";
            rc1 b " ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
        ;;
        c)
	    rdt && rdt && rdt && rdt && rdt
	    rdt && rdt && rdt && rdt && rdt
            rdt && rdt && rdt && rdt && rdt
	    rdt && rdt && rdt && rdt && rdt
	;;
esac
} # -- colors rendering test    
alias ct='color_test'

curmv(){
    local n="${2:-1}"
    case "$1" in
        # ── Navigation ──
        t|top)       printf "\033[H" ;;              # ← home (top-left)
        b|bottom)    printf "\033[999B" ;;           # ← ไปล่างสุด
        u|up)        printf "\033[%dA" "$n" ;;       # ← ขึ้น N บรรทัด
        d|down)      printf "\033[%dB" "$n" ;;       # ← ลง N บรรทัด
        l|left)      printf "\033[%dD" "$n" ;;       # ← ซ้าย N คอลัมน์
        r|right)     printf "\033[%dC" "$n" ;;       # ← ขวา N คอลัมน์
        # ── Erase ──
        a|above)     printf "\033[2K" ;;             # ← ลบทั้งบรรทัด
        e|end)       printf "\033[K" ;;              # ← ลบจาก cursor → จบบรรทัด
        s|start)     printf "\033[1K" ;;             # ← ลบจาก cursor → ต้นบรรทัด
        c|clear)     printf "\033[2J" ;;             # ← ลบทั้งจอ
        cc|cls)      printf "\033[2J\033[H" ;;      # ← ลบทั้งจอ + กลับบนซ้าย
        # ── Save / Restore ──
        sv|save)     printf "\033[s" ;;              # ← จำตำแหน่ง cursor
        rv|restore)  printf "\033[u" ;;              # ← กลับตำแหน่งที่จำไว้
        # ── Help ──
        ?|-h|--help)
            cat <<'HELP'
curmv — Cursor Movement Tool
Usage: curmv <command> [count]

Navigation:
  t|top         cursor → home (บนซ้าย)
  b|bottom      cursor → ล่างสุด
  u|up    [n]   ขึ้น N บรรทัด        (default 1)
  d|down  [n]   ลง N บรรทัด
  l|left  [n]   ซ้าย N คอลัมน์
  r|right [n]   ขวา N คอลัมน์

Erase:
  a|above       ลบทั้งบรรทัดปัจจุบัน
  e|end         ลบจาก cursor → จบบรรทัด
  s|start       ลบจาก cursor → ต้นบรรทัด
  c|clear       ลบทั้งจอ
  cc|cls        ลบทั้งจอ + กลับบนซ้าย

Save/Restore:
  sv|save       จำตำแหน่ง cursor
  rv|restore    กลับตำแหน่งที่จำไว้
HELP
            ;;
        *) printf "curmv: unknown '%s' (try: curmv ?)\n" "$1" ;;
    esac
}

