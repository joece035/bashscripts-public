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
we() {
    get_visible_width2 "$@"
}
#-- git tools
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
                  (git pull --rebase || { cn 9 b "PULL FAILED — resolve conflicts"; return 1; }) && \
                  git push && \
                  cn 10 bi "DONE push" ;;
        *)        git "$@" ;;
     esac               
  fi
}
#--- git_ alias
g() {
    if (( $# <= 1 )); then
        git_ all "${1:-$(date)}"
    else
        git_ "$@"
    fi
}
clone() {

    local repo="$SSOT"

    if [[ -d "${repo}" ]]; then
         rm -rf "${repo}" && cn 10 b " done deleted ${repo} " &&
         cd $HOME
         git "clone" "git@github.com:joece035/bashscripts.git" &&
         echo "Done cloning BASHSCRIPTS"
    else
         echo " ${repo} not found in HOME "
         cd $HOME
         git "clone" "git@github.com:joece035/bashscripts.git" &&
         echo "Done cloning BASHSCRIPTS"
    fi

    case "$JOE_ENV" in
        TERMUX|MUMU) exec zsh ;;
        WSL|GIT-BASH) exec bash ;;
        *) return 0
    esac
}
idf_del(){

    local idf_dir=${1:-$SSOT}
    # ค้นหาไฟล์แล้วเก็บเข้าตัวแปร
    local idf_files
    idf_files=$(find "$idf_dir" -type f -iname "*Zone.Identifier*" -print0)
    
    # 1. เช็คว่าถ้าไม่พบไฟล์ ให้แจ้งเตือนแล้วจบการทำงานทันที
    if [[ -z "$idf_files" ]]; then
        c 198 bi "not found any Zone.Identifier files in "; c gr b " >> "; cn 10 b "$idf_dir" 
        return 1
    fi
    
    # 2. นับจำนวนไฟล์จากตัวแปรที่มีอยู่แล้ว (ใช้วิธีนับจำนวนบรรทัด)
    local files_count
    files_count=$(wc -l <<< "$idf_files")
    
    c gr "" "found "; c 10 b "$files_count ";cn gr "" "files"
    echo ""
    cn 45 b "$idf_files" &&

    cn 227 bu "DELETE all ? (y/n)"
    read -r choice
    
    case "$choice" in
        y|Y|yes|YES)
   
            while IFS= read -r file; do
                 rm -f "$file"
            done <<< "$idf_files"

            c gr "" "all  "; c 45 bi "$files_count"; cn gr "" "  Zone.Identifier files are removed"
            ;;
        *)
            return 0
            ;;
    esac            

    
}
conf_def(){
    
    local conf_dir=${1:-$SSOT}
    
    # ค้นหาไฟล์แล้วเก็บเข้าตัวแปร
    local conf_files
    conf_files=$(find "$conf_dir" -type f -iname "*conflict*" -print0)
    
    # 1. เช็คว่าถ้าไม่พบไฟล์ ให้แจ้งเตือนแล้วจบการทำงานทันที
    if [[ -z "$conf_files" ]]; then
        c 198 bi "not found any conflict files in "; c gr b ">>"; cn 10 b " $conf_dir" 
        return 1
    fi
    
    # 2. นับจำนวนไฟล์จากตัวแปรที่มีอยู่แล้ว (ใช้วิธีนับจำนวนบรรทัด)
    local files_count
    files_count=$(wc -l <<< "$conf_files")
    
    c gr "" "found "; c 10 b "$files_count ";cn gr "" "files"
    echo ""
    cn 45 b "$conf_files" &&

    cn 227 bu "DELETE all ? (y/n)"
    read -r choice
    
    case "$choice" in
        y|Y|yes|YES)
   
            while IFS= read -r file; do
                 rm -f "$file"
            done <<< "$conf_files"

            c gr "" "all  "; c 45 bi "$files_count"; cn gr "" "  conflict files are removed"
            ;;
        *)
            return 0
            ;;
    esac            

    
}
del(){
    local t=${1:-i}
    shift
    case "${t}" in
        c|conf|conflict) conf_def "$@" ;;
        i|idf|indentify) idf_del "$@" ;;
        *) c 196 b "RUN";c 45 b "trash_del < c or i >" ;;
    esac

}
e(){
    local m=${1:-}
    shift
    case $m in
        -n) 
            printf '%s\n' "$@" ;;
        *)
            printf '%s ' "$@" ;;
    esac        

}