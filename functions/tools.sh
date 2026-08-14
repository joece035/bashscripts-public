#!/bin/bash
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
#        TOOLS is LOADED BY 00-fm-loader.sh         #
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
# -- Library module (sourced by 00-fm-loader.sh).
# -- NOTE: treegu() + alias t ถูกย้ายไปเป็น canonical ที่
#    tools/merge.sh แล้ว (เดิมซ้ำกันทั้ง 2 ไฟล์)
# -- ฟังก์ชันทั่วไปใหม่ ๆ ใส่ตรงนี้ได้

mkdir_() {
    local is_dir=0
    [[ "${1:-}" == "-d" ]] && is_dir=1 && shift
    local target="${1:-$HOME/test.txt}"

    if (( is_dir )); then
        mkdir -p "$target"
        echo "✅ โฟลเดอร์ถูกสร้างเรียบร้อย: $target"
    else
        mkdir -p "$(dirname "$target")"
        touch "$target"
        echo "✅ ไฟล์ถูกสร้างเรียบร้อย: $target"
    fi
}

# -- ฟังก์ชั่นหา Display Width ที่แท้จริง (รวม Emoji และตัด ANSI Code ออก)
get_w() {
    local text="$1"
    # ตัด ANSI escape code ออกก่อนนับ
    local plain_text=$(echo -e "$text" | sed 'r'%"$(printf '\033')"\%\%b%g | sed 's/\x1b\[[0-9;]*m//g')
    
    # ใช้ python3 นับความกว้างหน้าจอจริง
    python3 -c "import unicodeattr, sys; import unicodedata; print(sum(2 if unicodedata.east_asian_width(c) in 'WF' else 1 for c in '''$plain_text'''))" 2>/dev/null || echo "${#plain_text}"
}
ew() {
    local text="$1"
    local width
    width=$(get_visible_width "$text")
    echo "$width"
}
get_visible_width2() {
    local text="$1"

    python3 - "$text" <<'PY' 2>/dev/null
import sys
import re
from wcwidth import wcswidth

text = sys.argv[1]

# Remove ANSI CSI escape sequences
text = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', text)

width = wcswidth(text)

print(max(width, 0))
PY
}
e() {
    get_visible_width2 "$@"
}


git_() {
  local repo=${SSOT:-"$HOME/bashscripts"}
  cd $repo &&
  if [[ -n "$1" ]]; then
     case "${1:-}" in
        s|status) git status ;;
        c|commit) git commit -m "$2" ;;
        a|add)    git add -A ;;
        all)      git add -A && \
                  git commit -m "${2}" && \
                  git push && \
                  cn 10 bi "DONE push" ;;
        *)        git "$@" ;;
     esac               
  fi
}

clone() {

    local repo="$SSOT"
    if [[ -d "${repo}" ]]; then
         rm -rf "${repo}" && cn 10 b " done deleted ~/bashscripts "
         cd $HOME
         git "clone" "git@github.com:joece035/bashscripts.git" &&
         echo "Done"
    else
         echo " $repo not found "
         cd $HOME
         git "clone" "git@github.com:joece035/bashscripts.git" &&
         echo "Done cloning repo.."
    fi

    case "$JOE_ENV" in
        TERMUX|MUMU) exec zsh ;;
        WSL|GIT-BASH) exec bash ;;
        *) return 0
    esac      
}
