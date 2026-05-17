#!/usr/bin/env bash
# =============================================================================
#  ███████╗██╗██╗     ███████╗███╗   ███╗ ██████╗ ██████╗
#  ██╔════╝██║██║     ██╔════╝████╗ ████║██╔════╝ ██╔══██╗
#  █████╗  ██║██║     █████╗  ██╔████╔██║██║  ███╗██████╔╝
#  ██╔══╝  ██║██║     ██╔══╝  ██║╚██╔╝██║██║   ██║██╔══██╗
#  ██║     ██║███████╗███████╗██║ ╚═╝ ██║╚██████╔╝██║  ██║
#  ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
#  File Manager CLI — v3.0 | For Everyone + Learn Mode
# =============================================================================
# Usage: source filemanager.sh        (load all functions)
#        fm help                      (show help menu)
#        fm learn on                  (เปิด Learn Mode — ดูคำสั่งจริง)
#        fm learn off                 (ปิด Learn Mode)
# =============================================================================
clear
# ─────────────────────────────────────────────────────────────────
# COLORS & STYLES
# ─────────────────────────────────────────────────────────────────
RED='\033[0;31m';    LRED='\033[1;31m'
GREEN='\033[0;32m';  LGREEN='\033[1;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; LCYAN='\033[1;36m'
BLUE='\033[0;34m';   LBLUE='\033[1;34m'
MAGENTA='\033[0;35m';LMAGENTA='\033[1;35m'
WHITE='\033[1;37m';  GRAY='\033[0;37m'
BOLD='\033[1m';      DIM='\033[2m';  ITALIC='\033[3m'
UNDERLINE='\033[4m'; RESET='\033[0m'
ORANGE='\033[38;5;214m'

# ─────────────────────────────────────────────────────────────────
# LEARN MODE TOGGLE
# ─────────────────────────────────────────────────────────────────
FM_LEARN=${FM_LEARN:-0}

# _learn_box <title> <cmd_line> [flag|desc] [flag|desc] ...
# แสดง box อธิบายคำสั่งจริงที่กำลังรัน — จะแสดงเฉพาะตอน FM_LEARN=1
_learn_box() {
  [[ "$FM_LEARN" != "1" ]] && return
  local title="$1"; shift
  local cmd="$1";   shift

  echo ""
  echo -e "  ${ORANGE}┌─ 📚 LEARN MODE ─────────────────────────────────────────────────┐${RESET}"
  printf  "  ${ORANGE}│${RESET}  ${BOLD}%-65s${ORANGE}│${RESET}\n" "$title"
  echo -e "  ${ORANGE}├─────────────────────────────────────────────────────────────────┤${RESET}"
  echo -e "  ${ORANGE}│${RESET}  ${DIM}Raw command:${RESET}"
  echo -e "  ${ORANGE}│${RESET}  ${LGREEN}\$ ${cmd}${RESET}"

  if [[ $# -gt 0 ]]; then
    echo -e "  ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}  ${DIM}Flags & options อธิบาย:${RESET}"
    for annotation in "$@"; do
      local flag="${annotation%%|*}"
      local desc="${annotation##*|}"
      printf "  ${ORANGE}│${RESET}  ${CYAN}%-22s${RESET}  ${GRAY}%s${RESET}\n" "$flag" "$desc"
    done
  fi
  echo -e "  ${ORANGE}└─────────────────────────────────────────────────────────────────┘${RESET}"
  echo ""
}

fm_learn() {
  local mode="${1:-toggle}"
  case "$mode" in
    on|1)
      FM_LEARN=1
      echo ""
      echo -e "  ${ORANGE}📚 Learn Mode ${LGREEN}ON${RESET}  — ทุก command จะแสดงคำสั่งจริงก่อนรัน"
      echo -e "  ${DIM}  ปิดด้วย: ${RESET}${CYAN}fm learn off${RESET}"
      echo ""
      ;;
    off|0)
      FM_LEARN=0
      echo ""
      echo -e "  ${ORANGE}📚 Learn Mode ${LRED}OFF${RESET}"
      echo ""
      ;;
    toggle|*)
      if [[ "$FM_LEARN" == "1" ]]; then fm_learn off; else fm_learn on; fi
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────
# INTERNAL HELPERS
# ─────────────────────────────────────────────────────────────────
_ok()    { echo -e "${LGREEN}  ✔  ${RESET}${GREEN}$*${RESET}"; }
_warn()  { echo -e "${YELLOW}  ⚠  ${RESET}${YELLOW}$*${RESET}"; }
_err()   { echo -e "${LRED}  ✘  ${RESET}${RED}$*${RESET}" >&2; }
_info()  { echo -e "${LCYAN}  ℹ  ${RESET}${CYAN}$*${RESET}"; }
_step()  { echo -e "${LBLUE}  →  ${RESET}${BOLD}$*${RESET}"; }
_sep()   { echo -e "${DIM}─────────────────────────────────────────────────────${RESET}"; }

_confirm() {
  local msg="${1:-Are you sure?}"
  echo -en "${YELLOW}  ❓  ${RESET}${BOLD}${msg}${RESET} ${DIM}[y/N]${RESET} "
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

_human_size() {
  local bytes=$1
  if   (( bytes >= 1073741824 )); then printf "%.1f GB" "$(echo "scale=1; $bytes/1073741824" | bc)"
  elif (( bytes >= 1048576    )); then printf "%.1f MB" "$(echo "scale=1; $bytes/1048576"    | bc)"
  elif (( bytes >= 1024       )); then printf "%.1f KB" "$(echo "scale=1; $bytes/1024"       | bc)"
  else printf "%d B" "$bytes"; fi
}

# ═════════════════════════════════════════════════════════════════
#  HELP MENU
# ═════════════════════════════════════════════════════════════════
fm_help() {
  local cat="${1:-all}"
  echo ""
  echo -e "${LCYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${LCYAN}║${RESET}  ${BOLD}${WHITE}📁  FILE MANAGER CLI  v3.0  —  Quick Reference Guide${RESET}            ${LCYAN}║${RESET}"
  echo -e "${LCYAN}║${RESET}  ${DIM}source filemanager.sh  →  fm help  →  fm learn on${RESET}              ${LCYAN}║${RESET}"
  echo -e "${LCYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"

  if [[ "$cat" == "all" || "$cat" == "nav" ]]; then
    echo ""
    echo -e "  ${LMAGENTA}🧭  NAVIGATION & LISTING${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm ls"     "fm ls [path]"           "แสดงไฟล์ทั้งหมดแบบสวยงาม"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm lsa"    "fm lsa [path]"          "แสดงรวมไฟล์ซ่อน (.dotfiles)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm tree"   "fm tree [path] [depth]" "แสดงโครงสร้างโฟลเดอร์แบบ tree"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm goto"   "fm goto <path>"         "เปลี่ยน directory พร้อม bookmark"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm back"   "fm back"                "กลับ directory ก่อนหน้า"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm home"   "fm home"                "กลับ Home directory"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm pwd"    "fm pwd"                 "บอกว่าอยู่ที่ไหนตอนนี้"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi

  if [[ "$cat" == "all" || "$cat" == "file" ]]; then
    echo ""
    echo -e "  ${YELLOW}📄  FILE OPERATIONS${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm cp"     "fm cp <src> <dst>"      "คัดลอกไฟล์/โฟลเดอร์ (มี progress)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm mv"     "fm mv <src> <dst>"      "ย้ายไฟล์/โฟลเดอร์ (ยืนยันก่อน)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm rm"     "fm rm <file/dir>"       "ลบไฟล์ (ถามยืนยัน + ส่ง trash)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm rn"     "fm rn <old> <new>"      "เปลี่ยนชื่อไฟล์"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm mk"     "fm mk <name>"           "สร้างไฟล์เปล่าใหม่"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm mkdir"  "fm mkdir <name>"        "สร้างโฟลเดอร์ (รวม parent)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm touch"  "fm touch <file>"        "สร้าง/อัปเดต timestamp ไฟล์"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm link"   "fm link <src> <dst>"    "สร้าง symlink"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi

  if [[ "$cat" == "all" || "$cat" == "search" ]]; then
    echo ""
    echo -e "  ${LBLUE}🔍  SEARCH & INFORMATION${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm find"     "fm find <name> [path]"    "ค้นหาไฟล์ตามชื่อ"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm grep"     "fm grep <text> [path]"    "ค้นหาข้อความในไฟล์"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm findext"  "fm findext <.ext> [path]" "ค้นหาตามนามสกุลไฟล์"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm findsize" "fm findsize <+/-N> [MB]"  "ค้นหาตามขนาดไฟล์"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm info"     "fm info <file>"           "แสดงรายละเอียดไฟล์ครบถ้วน"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm size"     "fm size [path]"           "ขนาดรวมของไฟล์/โฟลเดอร์"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm recent"   "fm recent [N] [path]"     "ไฟล์ที่แก้ไขล่าสุด N รายการ"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm big"      "fm big [N] [path]"        "ไฟล์ขนาดใหญ่สุด N อันดับ"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm dup"      "fm dup [path]"            "หาไฟล์ที่ซ้ำกัน (by checksum)"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi

  if [[ "$cat" == "all" || "$cat" == "zip" ]]; then
    echo ""
    echo -e "  ${LRED}🗜️   COMPRESS & ARCHIVE${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm zip"     "fm zip <out.zip> <src>"     "บีบอัดเป็น ZIP"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm unzip"   "fm unzip <file.zip> [dst]"  "แตก ZIP ไปยัง path"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm tar"     "fm tar <out.tar.gz> <src>"  "บีบอัดเป็น tar.gz"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm untar"   "fm untar <file.tar.gz>"     "แตก tar.gz"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm ziplist" "fm ziplist <file.zip>"      "ดูรายการในไฟล์ ZIP"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi

  if [[ "$cat" == "all" || "$cat" == "perm" ]]; then
    echo ""
    echo -e "  ${LMAGENTA}🔐  PERMISSIONS & OWNERSHIP${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm perm"   "fm perm <file>"         "ดู permission ปัจจุบัน"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm chmod"  "fm chmod <mode> <file>" "เปลี่ยน permission (ex: 755)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm chown"  "fm chown <user> <file>" "เปลี่ยนเจ้าของไฟล์"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm mkexec" "fm mkexec <file>"       "ทำให้ไฟล์รันได้ (+x)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm rmexec" "fm rmexec <file>"       "ถอด permission รัน (-x)"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi

  if [[ "$cat" == "all" || "$cat" == "disk" ]]; then
    echo ""
    echo -e "  ${LCYAN}💾  DISK & STORAGE${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm df"         "fm df"             "ดู disk usage ทุก drive"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm du"         "fm du [path]"      "ดูขนาดแต่ละโฟลเดอร์ย่อย"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm clean"      "fm clean [path]"   "ลบไฟล์ tmp/cache ชั่วคราว"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm trash"      "fm trash"          "ดูสิ่งที่ถูกลบ (trash bin)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm emptytrash" "fm emptytrash"     "ล้าง trash bin (ถามยืนยัน)"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi

  if [[ "$cat" == "all" || "$cat" == "batch" ]]; then
    echo ""
    echo -e "  ${YELLOW}⚡  BATCH OPERATIONS${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm bren"    "fm bren <pattern> <rep>"  "เปลี่ยนชื่อหลายไฟล์พร้อมกัน"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm bcp"     "fm bcp <dst> <files...>"  "คัดลอกหลายไฟล์ไปปลายทาง"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm bmv"     "fm bmv <dst> <files...>"  "ย้ายหลายไฟล์ไปปลายทาง"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm brm"     "fm brm <pattern> [path]"  "ลบหลายไฟล์ตาม pattern"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm sortdir" "fm sortdir <src> <dst>"   "จัดเรียงไฟล์ตามนามสกุลอัตโนมัติ"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm datedir" "fm datedir <src> <dst>"   "จัดเรียงไฟล์ตามวันที่แก้ไข"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi
  
  if [[ "$cat" == "all" || "$cat" == "sync" ]]; then
    echo ""
    echo -e "  ${LCYAN}🌍  SYNC & REMOTE (3-WORLDS)${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-28s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm world"  "fm world"             "ตรวจสอบ IP และสถานะเครื่องอื่น"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm ssh"    "fm ssh <tm|tw|wsl>"   "เชื่อมต่อ SSH ไปยังเครื่องอื่น"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm push"   "fm push <src> [dst]"  "ส่งไฟล์ไป Termux (Update only)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm pull"   "fm pull <src> [dst]"  "ดึงไฟล์จาก Termux (Update only)"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm rls"    "fm rls [path]"        "ดูรายการไฟล์บน Termux"
    printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-28s${RESET}  %s\n" "fm rrun"   "fm rrun <cmd>"        "รันคำสั่งบน Termux โดยตรง"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  fi

  local learn_status="${LRED}OFF${RESET}"
  [[ "$FM_LEARN" == "1" ]] && learn_status="${LGREEN}ON${RESET}"
  echo ""
  echo -e "  ${DIM}┌──────────────────────────────────────────────────────────────────┐${RESET}"
  echo -e "  ${DIM}│${RESET}  ${BOLD}fm help${RESET} ${DIM}<category>${RESET}  ${CYAN}nav│file│search│zip│perm│disk│batch│sync${RESET}  ${DIM}│${RESET}"
  echo -e "  ${DIM}│${RESET}  ${ORANGE}📚 Learn Mode:${RESET} ${learn_status}    พิมพ์ ${CYAN}fm learn on/off${RESET} เพื่อสลับ         ${DIM}│${RESET}"
  echo -e "  ${DIM}└──────────────────────────────────────────────────────────────────┘${RESET}"
  echo ""
}

# ═════════════════════════════════════════════════════════════════
#  NAVIGATION
# ═════════════════════════════════════════════════════════════════

fm_ls() {
  local target="${1:-.}"
  [[ ! -e "$target" ]] && { _err "ไม่พบ: $target"; return 1; }

  _learn_box "fm ls — แสดงรายการไฟล์แบบ formatted" \
    "ls -1p \"$target\" 2>/dev/null | sed 's|^|$target/|' | sort -t/ -k2 | while read item; do stat... done" \
    "ls -1p         |แสดงทีละบรรทัด (1 file per line ไม่ใช่แบบ grid)" \
    "sed            |เติม path เต็มเข้าไปข้างหน้าชื่อไฟล์แต่ละอัน" \
    "sort           |เรียงลำดับรายการไฟล์" \
    "while read     |วนลูปเพื่ออ่าน stat ของแต่ละไฟล์ทีละบรรทัด" \
    "stat -c \"%A\"  |อ่าน permission string เช่น -rwxr-xr-x" \
    "stat -c \"%s\"  |อ่านขนาดไฟล์เป็น bytes แล้ว fm แปลงเป็น KB/MB" \
    "stat -c \"%y\"  |อ่านวันที่ modified ล่าสุด" \
    "file -b        |ตรวจ file type จาก magic bytes (ไม่ใช่แค่นามสกุล)"

  echo ""
  echo -e "  ${LCYAN}📂  $(realpath "$target")${RESET}"
  _sep
  printf "  ${BOLD}${UNDERLINE}%-6s  %-10s  %-8s  %-20s  %s${RESET}\n" \
    "PERM" "SIZE" "TYPE" "MODIFIED" "NAME"
  _sep

  local count=0
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    local name perm size type mdate icon color
    name=$(basename "$item")
    perm=$(stat -c "%A" "$item" 2>/dev/null || stat -f "%Sp" "$item" 2>/dev/null || echo "?")
    mdate=$(stat -c "%y" "$item" 2>/dev/null | cut -c1-16 || stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$item" 2>/dev/null || echo "?")
    size="—"

    local link_target=""
    if   [[ -L "$item" ]]; then 
      icon="🔗"; type="symlink"; color="${CYAN}"
      link_target=$(readlink "$item" 2>/dev/null)
    elif [[ -d "$item" ]]; then icon="📁"; type="dir";     color="${LBLUE}"
    elif [[ -x "$item" ]]; then icon="⚙️ "; type="exec";    color="${LGREEN}"
    else                        icon="📄"; type="file";    color="${WHITE}"; fi

    if [[ -f "$item" ]]; then
      local raw_size
      raw_size=$(stat -c "%s" "$item" 2>/dev/null || stat -f "%z" "$item" 2>/dev/null || echo 0)
      size=$(_human_size "$raw_size")
    fi

    if [[ -n "$link_target" ]]; then
      printf "  ${DIM}%-6s${RESET}  ${GRAY}%-10s${RESET}  ${DIM}%-8s${RESET}  ${DIM}%-20s${RESET}  ${color}%s %s${RESET} ${DIM}->${RESET} ${LGREEN}%s${RESET}\n" \
        "$perm" "$size" "$type" "$mdate" "$icon" "$name" "$link_target"
    else
      printf "  ${DIM}%-6s${RESET}  ${GRAY}%-10s${RESET}  ${DIM}%-8s${RESET}  ${DIM}%-20s${RESET}  ${color}%s %s${RESET}\n" \
        "$perm" "$size" "$type" "$mdate" "$icon" "$name"
    fi
    (( count++ ))
  done < <(ls -1p "$target" 2>/dev/null | sed "s|^|$target/|" | sort -t/ -k2)

  _sep
  echo -e "  ${DIM}Total: ${RESET}${BOLD}${count} items${RESET}"
  echo ""
}

fm_lsa() {
  local target="${1:-.}"
  _learn_box "fm lsa — แสดงไฟล์ทั้งหมดรวมไฟล์ซ่อน" \
    "ls -1ap \"$target\"" \
    "-1  |แสดงทีละบรรทัด" \
    "-a  |all — แสดงไฟล์ซ่อน (dotfiles) เช่น .bashrc .env .git" \
    "-p  |ใส่ / ต่อท้ายโฟลเดอร์"
  fm_ls "$target"
}

fm_tree() {
  local target="${1:-.}"
  local depth="${2:-3}"
  _learn_box "fm tree — แสดงโครงสร้างโฟลเดอร์แบบ tree" \
    "tree -L $depth --dirsfirst -C \"$target\"" \
    "-L $depth      |แสดงลึกสุด $depth ระดับ" \
    "--dirsfirst    |แสดงโฟลเดอร์ก่อนไฟล์เสมอ" \
    "-C             |เปิดสี ANSI color" \
    "(fallback)     |ถ้าไม่มี tree ใช้ find -maxdepth $depth แทน"
  echo ""
  if command -v tree &>/dev/null; then
    tree -L "$depth" --dirsfirst -C "$target"
  else
    _warn "tree ไม่ได้ติดตั้ง — ใช้ find แทน (sudo apt install tree)"
    find "$target" -maxdepth "$depth" | sort | while IFS= read -r f; do
      local lvl; lvl="${f//[^\/]/}"; local d=${#lvl}
      printf '%*s├── %s\n' "$((d*2))" '' "$(basename "$f")"
    done
  fi
  echo ""
}

FM_PREV_DIR=""

fm_goto() {
  [[ -z "$1" ]] && { _err "Usage: fm goto <path>"; return 1; }
  [[ ! -d "$1" ]] && { _err "ไม่พบโฟลเดอร์: $1"; return 1; }
  _learn_box "fm goto — เปลี่ยน directory" \
    "cd \"$1\"" \
    "cd             |change directory — เปลี่ยน working directory ของ shell ปัจจุบัน" \
    "(bookmark)     |fm เก็บ path เดิมไว้ใน \$FM_PREV_DIR เพื่อให้ fm back ใช้ได้"
  FM_PREV_DIR="$PWD"
  cd "$1" && _ok "ย้ายมาที่: $(pwd)"
}

fm_back() {
  [[ -z "$FM_PREV_DIR" ]] && { _warn "ไม่มี history — ลอง fm home"; return 1; }
  _learn_box "fm back — กลับ directory ก่อนหน้า" \
    "cd \"$FM_PREV_DIR\"" \
    "cd <path>      |fm เก็บ path ก่อนหน้าไว้ใน \$FM_PREV_DIR แล้วสลับกลับ" \
    "(swap)         |แล้ว swap ค่า ทำให้ back/forth ไปมาได้"
  local tmp="$PWD"
  cd "$FM_PREV_DIR" && _ok "กลับมาที่: $(pwd)"
  FM_PREV_DIR="$tmp"
}

fm_home() {
  _learn_box "fm home — กลับ Home directory" \
    "cd ~" \
    "~              |tilde (~) = shortcut ของ \$HOME เช่น /home/joe หรือ /root" \
    "\$HOME          |environment variable ที่ shell ตั้งให้อัตโนมัติตอน login"
  cd ~ && _ok "กลับ Home: $(pwd)"
}

fm_pwd() {
  _learn_box "fm pwd — แสดง path ปัจจุบัน" \
    "pwd" \
    "pwd            |print working directory — บอกว่าตอนนี้อยู่ที่ path ไหน" \
    "realpath       |fm ใช้ realpath เพิ่มเติมเพื่อ resolve symlink ให้เป็น path จริง"
  echo ""
  echo -e "  ${LCYAN}📍  Current Location${RESET}"
  echo -e "  ${BOLD}$(pwd)${RESET}"
  echo ""
}

# ═════════════════════════════════════════════════════════════════
#  FILE OPERATIONS
# ═════════════════════════════════════════════════════════════════

fm_cp() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm cp <src> <dst>"; return 1; }
  [[ ! -e "$1" ]] && { _err "ไม่พบต้นทาง: $1"; return 1; }
  if command -v rsync &>/dev/null; then
    _learn_box "fm cp — คัดลอกไฟล์ด้วย rsync (มี progress)" \
      "rsync -ah --progress \"$1\" \"$2\"" \
      "-a             |archive mode = รวม -r(recursive) -l(symlinks) -p(permissions) -t(timestamps)" \
      "-h             |human-readable ขนาดไฟล์ แสดงเป็น KB/MB แทน bytes" \
      "--progress     |แสดง progress bar ขณะคัดลอก" \
      "(ต่างจาก cp)   |rsync เร็วกว่า cp สำหรับไฟล์ใหญ่ และ copy ได้แม่นยำกว่า"
    _step "คัดลอก: $1  →  $2"
    rsync -ah --progress "$1" "$2" && _ok "คัดลอกสำเร็จ"
  else
    _learn_box "fm cp — คัดลอกไฟล์ด้วย cp" \
      "cp -rv \"$1\" \"$2\"" \
      "-r             |recursive — คัดลอกโฟลเดอร์ทั้งหมดรวมโฟลเดอร์ย่อย" \
      "-v             |verbose — แสดงชื่อทุกไฟล์ที่กำลังคัดลอก" \
      "(rsync)        |ถ้าติดตั้ง rsync จะใช้แทน cp เพราะมี progress bar"
    _step "คัดลอก: $1  →  $2"
    cp -rv "$1" "$2" && _ok "คัดลอกสำเร็จ"
  fi
}

fm_mv() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm mv <src> <dst>"; return 1; }
  [[ ! -e "$1" ]] && { _err "ไม่พบต้นทาง: $1"; return 1; }
  _learn_box "fm mv — ย้ายไฟล์/โฟลเดอร์" \
    "mv -v \"$1\" \"$2\"" \
    "mv             |move — ถ้า src/dst อยู่ใน disk เดียวกัน = แค่เปลี่ยน pointer (เร็วมาก)" \
    "-v             |verbose — แสดงชื่อที่ถูกย้าย" \
    "(ยืนยัน)       |fm เพิ่มขั้นตอนถามยืนยันก่อน เพราะ mv ย้อนกลับไม่ได้ง่ายๆ"
  _confirm "ย้าย '$1' → '$2'?" || { _info "ยกเลิก"; return 0; }
  mv -v "$1" "$2" && _ok "ย้ายสำเร็จ"
}

fm_rm() {
  [[ -z "$1" ]] && { _err "Usage: fm rm <file>"; return 1; }
  [[ ! -e "$1" ]] && { _err "ไม่พบ: $1"; return 1; }
  if command -v trash &>/dev/null; then
    _learn_box "fm rm — ลบไฟล์ (ผ่าน trash-cli)" \
      "trash \"$1\"" \
      "trash          |ส่งไฟล์ไปที่ Trash แทนการลบตาย (สามารถ restore ได้)" \
      "(fallback)     |ถ้าไม่มี trash หรือ gio → ใช้ rm -rv แทน (ลบถาวร)" \
      "(tip)          |sudo apt install trash-cli เพื่อใช้ trash command"
  elif command -v gio &>/dev/null; then
    _learn_box "fm rm — ลบไฟล์ (ผ่าน gio trash)" \
      "gio trash \"$1\"" \
      "gio trash      |GNOME I/O — ส่งไฟล์ไป Trash แบบ freedesktop standard" \
      "(gio)          |ใช้ได้บน Linux desktop เช่น Ubuntu, Fedora, Arch"
  else
    _learn_box "fm rm — ลบไฟล์ถาวร (permanent)" \
      "rm -rv \"$1\"" \
      "rm             |remove — ลบไฟล์ถาวร ย้อนกลับไม่ได้!" \
      "-r             |recursive — ลบโฟลเดอร์พร้อมทุกอย่างข้างใน" \
      "-v             |verbose — แสดงทุกไฟล์ที่ถูกลบ" \
      "(tip)          |ติดตั้ง trash-cli เพื่อความปลอดภัย: sudo apt install trash-cli"
  fi
  _warn "กำลังจะลบ: $1"
  _confirm "ยืนยันการลบ?" || { _info "ยกเลิก — ไฟล์ปลอดภัย"; return 0; }
  if   command -v trash &>/dev/null; then trash "$1" && _ok "ส่งไป Trash สำเร็จ"
  elif command -v gio   &>/dev/null; then gio trash "$1" && _ok "ส่งไป Trash สำเร็จ"
  else rm -rv "$1" && _ok "ลบสำเร็จ (permanent)"; fi
}

fm_rn() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm rn <old> <new>"; return 1; }
  [[ ! -e "$1" ]] && { _err "ไม่พบ: $1"; return 1; }
  _learn_box "fm rn — เปลี่ยนชื่อไฟล์" \
    "mv -v \"$1\" \"$2\"" \
    "mv             |การเปลี่ยนชื่อใน Unix = mv ในโฟลเดอร์เดิม ไม่มี rename command แยก" \
    "-v             |แสดงชื่อเดิม → ชื่อใหม่"
  mv -v "$1" "$2" && _ok "เปลี่ยนชื่อ: $1 → $2"
}

fm_mk() {
  [[ -z "$1" ]] && { _err "Usage: fm mk <filename>"; return 1; }
  _learn_box "fm mk — สร้างไฟล์เปล่า" \
    "touch \"$1\"" \
    "touch          |สร้างไฟล์เปล่าถ้ายังไม่มี หรือ อัปเดต timestamp ถ้ามีอยู่แล้ว" \
    "(size=0)       |ไฟล์ที่สร้างมีขนาด 0 bytes พร้อมให้เขียนข้อมูลทีหลัง"
  touch "$1" && _ok "สร้างไฟล์: $1"
}

fm_mkdir() {
  [[ -z "$1" ]] && { _err "Usage: fm mkdir <dirname>"; return 1; }
  _learn_box "fm mkdir — สร้างโฟลเดอร์" \
    "mkdir -pv \"$1\"" \
    "-p             |parents — สร้างโฟลเดอร์ parent อัตโนมัติถ้ายังไม่มี เช่น a/b/c สร้างทีเดียว" \
    "-v             |verbose — แสดงแต่ละโฟลเดอร์ที่สร้าง" \
    "(ไม่มี -p)     |mkdir ปกติ error ถ้า parent ไม่มี แต่ -p จะข้ามไปเงียบๆ"
  mkdir -pv "$1" && _ok "สร้างโฟลเดอร์: $1"
}

fm_touch() {
  [[ -z "$1" ]] && { _err "Usage: fm touch <file>"; return 1; }
  _learn_box "fm touch — อัปเดต timestamp ไฟล์" \
    "touch \"$1\"" \
    "touch          |ถ้าไฟล์มีอยู่แล้ว: อัปเดต mtime (modified time) เป็นตอนนี้" \
    "               |ถ้าไฟล์ยังไม่มี: สร้างไฟล์เปล่าขนาด 0 bytes" \
    "(use case)     |ใช้บ่อยใน Makefile เพื่อ trigger rebuild โดยไม่ต้องแก้เนื้อหา"
  touch "$1" && _ok "อัปเดต timestamp: $1"
}

fm_link() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm link <src> <dst>"; return 1; }
  _learn_box "fm link — สร้าง symbolic link" \
    "ln -sv \"$1\" \"$2\"" \
    "ln             |link — สร้าง link ระหว่างไฟล์" \
    "-s             |symbolic — สร้าง symlink (shortcut) ไม่ใช่ hard link" \
    "-v             |verbose — แสดง link ที่สร้าง" \
    "(symlink)      |ไฟล์ dst จะชี้ไปที่ src เหมือน shortcut, ถ้าลบ src link จะ broken" \
    "(hardlink)     |ถ้าไม่ใส่ -s = hard link ชี้ inode เดียวกัน ลบ src ไฟล์ยังอยู่"
  ln -sv "$1" "$2" && _ok "สร้าง symlink: $2 → $1"
}

# ═════════════════════════════════════════════════════════════════
#  SEARCH & INFORMATION
# ═════════════════════════════════════════════════════════════════

fm_find() {
  local name="${1:?Usage: fm find <name> [path]}"
  local path="${2:-.}"
  _learn_box "fm find — ค้นหาไฟล์ตามชื่อ" \
    "find \"\$path\" -iname \"*\${name}*\" -not -path '*/\.*' 2>/dev/null | while IFS= read -r f; do ... done" \
    "find           |เครื่องมือค้นหาไฟล์ใน filesystem แบบ recursive" \
    "-iname         |case-insensitive name match, * = wildcard ใดๆ ก็ได้" \
    "-not -path     |ข้ามโฟลเดอร์ซ่อน (dotfiles) เช่น .git .cache" \
    "while read     |วนลูปเพื่อเช็คชนิดไฟล์ (folder/exec/file) เพื่อใส่ไอคอนสี" \
    "(ต่างจาก ls)   |find ลงลึกทุก subdirectory, ls แค่ชั้นเดียว"
  echo ""
  find "$path" -iname "*${name}*" -not -path '*/\.*' 2>/dev/null | while IFS= read -r f; do
    if   [[ -d "$f" ]]; then echo -e "  ${LBLUE}📁 $f${RESET}"
    elif [[ -x "$f" ]]; then echo -e "  ${LGREEN}⚙️  $f${RESET}"
    else echo -e "  ${WHITE}📄 $f${RESET}"; fi
  done
  echo ""
}

fm_grep() {
  local text="${1:?Usage: fm grep <text> [path]}"
  local path="${2:-.}"
  _learn_box "fm grep — ค้นหาข้อความในไฟล์" \
    "grep -rl --color=always \"\$text\" \"\$path\" 2>/dev/null | while IFS= read -r f; do grep -c ... done" \
    "grep           |global regular expression print — ค้นหา pattern ในไฟล์" \
    "-r             |recursive — ค้นทุกไฟล์ใน subdirectory" \
    "-l             |list only — แสดงแค่ชื่อไฟล์ที่เจอ ไม่แสดงทุก line" \
    "--color        |highlight คำที่เจอด้วยสี" \
    "(grep -n)      |อยากดู line number ด้วย ใช้ grep -rn แทน"
  echo ""
  grep -rl --color=always "$text" "$path" 2>/dev/null | while IFS= read -r f; do
    local hits; hits=$(grep -c "$text" "$f" 2>/dev/null)
    echo -e "  ${LGREEN}$f${RESET} ${DIM}($hits matches)${RESET}"
  done
  echo ""
}

fm_findext() {
  local ext="${1:?Usage: fm findext <.ext> [path]}"
  local path="${2:-.}"
  [[ "$ext" != .* ]] && ext=".$ext"
  _learn_box "fm findext — ค้นหาตามนามสกุล" \
    "find \"\$path\" -iname \"*\${ext}\" 2>/dev/null | while IFS= read -r f; do stat ... done" \
    "find           |ค้นหาแบบ recursive ทุก subdirectory" \
    "-iname \"*\$ext\" |* = ชื่อใดก็ได้, ลงท้ายด้วย \$ext (case-insensitive)" \
    "while read     |วนลูปใช้ stat อ่านขนาดไฟล์ทีละอันเพื่อแสดงผล" \
    "(นามสกุล)      |Unix ไม่ได้ใช้นามสกุลตัดสิน type จริงๆ แต่ find ใช้ชื่อล้วน"
  echo ""
  find "$path" -iname "*${ext}" 2>/dev/null | while IFS= read -r f; do
    local raw; raw=$(stat -c "%s" "$f" 2>/dev/null || stat -f "%z" "$f" 2>/dev/null || echo 0)
    printf "  ${WHITE}%-10s${RESET}  %s\n" "$(_human_size "$raw")" "$f"
  done
  echo ""
}

fm_findsize() {
  local spec="${1:?Usage: fm findsize <+/-NMB> [path]  ex: fm findsize +10 /home}"
  local path="${2:-.}"
  _learn_box "fm findsize — ค้นหาตามขนาดไฟล์" \
    "find \"\$path\" -type f -size \"\${spec}M\" 2>/dev/null | while IFS= read -r f; do stat ... done" \
    "-type f        |f = regular file เท่านั้น (ไม่รวมโฟลเดอร์)" \
    "-size \${spec}M  |+ = ใหญ่กว่า, - = เล็กกว่า, ไม่มี prefix = เท่ากับ (หน่วย M=MB)" \
    "(หน่วยอื่น)    |c=bytes k=KB M=MB G=GB เช่น -size +1G หาไฟล์ใหญ่กว่า 1GB"
  echo ""
  find "$path" -type f -size "${spec}M" 2>/dev/null | while IFS= read -r f; do
    local raw; raw=$(stat -c "%s" "$f" 2>/dev/null || stat -f "%z" "$f" 2>/dev/null || echo 0)
    printf "  ${YELLOW}%-10s${RESET}  %s\n" "$(_human_size "$raw")" "$f"
  done
  echo ""
}

fm_info() {
  local f="${1:?Usage: fm info <file>}"
  [[ ! -e "$f" ]] && { _err "ไม่พบ: $f"; return 1; }
  _learn_box "fm info — รายละเอียดไฟล์ครบถ้วน" \
    "stat \"$f\"  +  file -b \"$f\"  +  wc -lw \"$f\"" \
    "stat           |อ่าน metadata ของไฟล์จาก inode (ไม่ต้องเปิดไฟล์จริง)" \
    "stat -c '%A %a'|%A = symbolic perm (-rwxr-xr-x), %a = numeric (755)" \
    "stat -c '%U:%G'|%U = owner username, %G = group name" \
    "stat -c '%y'   |%y = mtime (last modified), %w = birth time (ถ้า fs รองรับ)" \
    "file -b        |อ่าน magic bytes ของไฟล์จริง เช่น 'PNG image data, 1920x1080'" \
    "wc -l / -w     |word count — นับ lines / words ในไฟล์"
  local raw size
  raw=$(stat -c "%s" "$f" 2>/dev/null || stat -f "%z" "$f" 2>/dev/null || echo 0)
  size=$(_human_size "$raw")
  echo ""
  echo -e "  ${LCYAN}╔══════════════════════════════════════════╗${RESET}"
  echo -e "  ${LCYAN}║${RESET}  ${BOLD}File Information${RESET}                         ${LCYAN}║${RESET}"
  echo -e "  ${LCYAN}╚══════════════════════════════════════════╝${RESET}"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Name:"        "$(basename "$f")"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Full Path:"   "$(realpath "$f")"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Size:"        "$size ($raw bytes)"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Type:"        "$(file -b "$f" 2>/dev/null || echo 'unknown')"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Permissions:" "$(stat -c '%A (%a)' "$f" 2>/dev/null || stat -f '%Sp' "$f")"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Owner:"       "$(stat -c '%U:%G' "$f" 2>/dev/null || stat -f '%Su:%Sg' "$f")"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Modified:"    "$(stat -c '%y' "$f" 2>/dev/null | cut -c1-19 || stat -f '%Sm' "$f")"
  printf "  ${DIM}%-18s${RESET}  %s\n" "Created:"     "$(stat -c '%w' "$f" 2>/dev/null | cut -c1-19 || stat -f '%SB' "$f")"
  if [[ -f "$f" ]]; then
    printf "  ${DIM}%-18s${RESET}  %s\n" "Lines/Words:" "$(wc -l < "$f" 2>/dev/null) / $(wc -w < "$f" 2>/dev/null)"
  fi
  echo ""
}

fm_size() {
  local target="${1:-.}"
  _learn_box "fm size — ขนาดรวมของไฟล์/โฟลเดอร์" \
    "du -sh \"$target\"" \
    "du             |disk usage — คำนวณขนาดที่ใช้จริงบน disk (รวม subdirectory)" \
    "-s             |summarize — แสดงแค่ยอดรวม ไม่แสดงทีละไฟล์" \
    "-h             |human-readable แสดงเป็น KB/MB/GB"
  _info "คำนวณขนาด: $target"
  du -sh "$target" 2>/dev/null | awk '{print "  Size: " $1 "  →  " $2}'
  echo ""
}

fm_recent() {
  local n="${1:-10}"
  local path="${2:-.}"
  _learn_box "fm recent — ไฟล์ที่แก้ไขล่าสุด" \
    "find \"$path\" -type f -printf '%T@ %p\n' | sort -rn | head -$n" \
    "-printf '%T@'  |T@ = mtime เป็น Unix timestamp (seconds since 1970-01-01)" \
    "sort -rn       |r = reverse (ใหม่สุดก่อน), n = numeric sort" \
    "head -$n        |แสดงแค่ $n บรรทัดแรก" \
    "date -d @ts    |แปลง Unix timestamp กลับเป็นวันที่อ่านได้"
  _info "ไฟล์ที่แก้ไขล่าสุด $n รายการใน $path"
  echo ""
  find "$path" -type f -not -path '*/\.*' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -"$n" \
    | while read -r ts f; do
        local date raw
        date=$(date -d "@${ts%.*}" "+%Y-%m-%d %H:%M" 2>/dev/null || date -r "${ts%.*}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "?")
        raw=$(stat -c "%s" "$f" 2>/dev/null || stat -f "%z" "$f" 2>/dev/null || echo 0)
        printf "  ${DIM}%s${RESET}  ${GRAY}%-8s${RESET}  %s\n" "$date" "$(_human_size "$raw")" "$f"
      done
  echo ""
}

fm_big() {
  local n="${1:-10}"
  local path="${2:-.}"
  _learn_box "fm big — ไฟล์ขนาดใหญ่ที่สุด" \
    "find \"$path\" -type f -printf '%s %p\n' | sort -rn | head -$n" \
    "-printf '%s'   |s = file size เป็น bytes" \
    "sort -rn       |เรียงจากมากไปน้อย (ใหญ่สุดก่อน)" \
    "head -$n        |เอาแค่ top $n" \
    "(tip)          |fm big 20 / เพื่อหาไฟล์ขนาดใหญ่ที่กิน disk"
  _info "ไฟล์ขนาดใหญ่ที่สุด $n อันดับใน $path"
  echo ""
  find "$path" -type f -not -path '*/\.*' -printf '%s %p\n' 2>/dev/null \
    | sort -rn | head -"$n" \
    | while read -r bytes f; do
        printf "  ${YELLOW}%-10s${RESET}  %s\n" "$(_human_size "$bytes")" "$f"
      done
  echo ""
}

fm_dup() {
  local path="${1:-.}"
  _learn_box "fm dup — หาไฟล์ที่ซ้ำกัน (by MD5 checksum)" \
    "find \"$path\" -type f -exec md5sum {} + | sort | awk 'seen[\$1]++'" \
    "-exec md5sum {}+|คำนวณ MD5 checksum ทุกไฟล์ (fingerprint ของเนื้อหา)" \
    "sort           |เรียงตาม checksum เพื่อให้ไฟล์เหมือนกันอยู่ติดกัน" \
    "awk seen[]     |ถ้า checksum ซ้ำ = ไฟล์เนื้อหาเหมือนกัน 100%" \
    "(md5 vs sha)   |md5 เร็วกว่า sha256 เหมาะกับการหา dup ไม่ใช่ security"
  _info "กำลังหาไฟล์ซ้ำใน $path (อาจใช้เวลาสักครู่)..."
  echo ""
  find "$path" -type f -not -path '*/\.*' -exec md5sum {} + 2>/dev/null \
    | sort | awk 'seen[$1]++ { print $0 }' \
    | while IFS= read -r line; do
        echo -e "  ${LRED}⚠ DUP:${RESET} $line"
      done
  echo ""
}

# ═════════════════════════════════════════════════════════════════
#  ARCHIVE
# ═════════════════════════════════════════════════════════════════

fm_zip() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm zip <output.zip> <source>"; return 1; }
  command -v zip &>/dev/null || { _err "zip ไม่ได้ติดตั้ง: sudo apt install zip"; return 1; }
  _learn_box "fm zip — บีบอัดเป็น ZIP" \
    "zip -r \"$1\" \"$2\"" \
    "zip            |สร้างไฟล์ .zip แบบ DEFLATE compression" \
    "-r             |recursive — รวมทุกไฟล์ใน subdirectory ด้วย" \
    "(zip vs tar)   |zip = เข้ากันได้ทุก OS (Windows เปิดได้), tar.gz compression ดีกว่า"
  _step "บีบอัด: $2 → $1"
  zip -r "$1" "$2" && _ok "สร้าง ZIP สำเร็จ: $1"
}

fm_unzip() {
  [[ -z "$1" ]] && { _err "Usage: fm unzip <file.zip> [destination]"; return 1; }
  [[ ! -f "$1" ]] && { _err "ไม่พบ: $1"; return 1; }
  local dst="${2:-.}"
  _learn_box "fm unzip — แตกไฟล์ ZIP" \
    "unzip -o \"$1\" -d \"$dst\"" \
    "unzip          |แตกไฟล์ .zip" \
    "-o             |overwrite — เขียนทับไฟล์เดิมโดยไม่ถาม" \
    "-d \"$dst\"      |destination — แตกไปยัง folder ที่ระบุ (สร้างให้อัตโนมัติ)" \
    "(tip)          |fm ziplist ก่อนแตก เพื่อดูว่ามีอะไรในไฟล์"
  _step "แตกไฟล์: $1 → $dst"
  unzip -o "$1" -d "$dst" && _ok "แตกไฟล์สำเร็จ"
}

fm_tar() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm tar <output.tar.gz> <source>"; return 1; }
  _learn_box "fm tar — บีบอัดเป็น tar.gz" \
    "tar -czvf \"$1\" \"$2\"" \
    "-c             |create — สร้าง archive ใหม่" \
    "-z             |gzip — บีบอัดด้วย gzip (.gz) หลังจาก tar รวมไฟล์" \
    "-v             |verbose — แสดงทุกไฟล์ที่เพิ่ม" \
    "-f \"$1\"        |file — ระบุชื่อ output file" \
    "(tar vs zip)   |tar.gz compression ratio ดีกว่า zip แต่ Windows ต้องใช้ 7-zip"
  _step "บีบอัด tar.gz: $2 → $1"
  tar -czvf "$1" "$2" && _ok "สร้าง tar.gz สำเร็จ: $1"
}

fm_untar() {
  [[ -z "$1" ]] && { _err "Usage: fm untar <file.tar.gz>"; return 1; }
  [[ ! -f "$1" ]] && { _err "ไม่พบ: $1"; return 1; }
  _learn_box "fm untar — แตกไฟล์ tar.gz" \
    "tar -xzvf \"$1\"" \
    "-x             |extract — แตกไฟล์ (ตรงข้ามกับ -c create)" \
    "-z             |gzip — บอกให้ tar รู้ว่าต้อง decompress gzip ก่อน" \
    "-v             |verbose — แสดงทุกไฟล์ที่แตก" \
    "-f \"$1\"        |file — ระบุชื่อ input file" \
    "(ดูก่อนแตก)   |tar -tzvf file.tar.gz เพื่อดูรายการก่อนแตก"
  _step "แตกไฟล์: $1"
  tar -xzvf "$1" && _ok "แตกสำเร็จ"
}

fm_ziplist() {
  [[ -z "$1" ]] && { _err "Usage: fm ziplist <file.zip>"; return 1; }
  [[ ! -f "$1" ]] && { _err "ไม่พบ: $1"; return 1; }
  _learn_box "fm ziplist — ดูรายการในไฟล์ ZIP" \
    "unzip -l \"$1\"" \
    "unzip -l       |list — แสดงรายการไฟล์ใน ZIP โดยไม่แตกออกมา" \
    "(tar)          |ดูรายการใน tar.gz: tar -tzvf file.tar.gz"
  _info "รายการใน $1:"
  echo ""
  unzip -l "$1"
  echo ""
}

# ═════════════════════════════════════════════════════════════════
#  PERMISSIONS
# ═════════════════════════════════════════════════════════════════

fm_perm() {
  [[ -z "$1" ]] && { _err "Usage: fm perm <file>"; return 1; }
  [[ ! -e "$1" ]] && { _err "ไม่พบ: $1"; return 1; }
  _learn_box "fm perm — ดู permission ของไฟล์" \
    "stat -c '%A %a %U' \"$1\"" \
    "stat -c '%A'   |symbolic: -rwxr-xr-x (อ่านง่าย)" \
    "stat -c '%a'   |numeric/octal: 755 (ใช้กับ chmod ได้โดยตรง)" \
    "stat -c '%U'   |owner username" \
    "(อ่าน perm)    |r=read w=write x=execute, กลุ่ม 1=owner 2=group 3=others"
  local p n
  p=$(stat -c '%A' "$1" 2>/dev/null || stat -f '%Sp' "$1" 2>/dev/null)
  n=$(stat -c '%a' "$1" 2>/dev/null || stat -f '%OLp' "$1" 2>/dev/null)
  echo ""
  echo -e "  ${BOLD}File:${RESET}       $1"
  echo -e "  ${BOLD}Symbolic:${RESET}   ${LCYAN}$p${RESET}"
  echo -e "  ${BOLD}Numeric:${RESET}    ${YELLOW}$n${RESET}"
  echo -e "  ${BOLD}Owner:${RESET}      $(stat -c '%U' "$1" 2>/dev/null)"
  echo ""
}

fm_chmod() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm chmod <mode> <file>  ex: fm chmod 755 script.sh"; return 1; }
  [[ ! -e "$2" ]] && { _err "ไม่พบ: $2"; return 1; }
  _learn_box "fm chmod — เปลี่ยน permission" \
    "chmod $1 \"$2\"" \
    "chmod          |change mode — เปลี่ยน permission bits ของไฟล์" \
    "$1             |octal: 7=rwx 6=rw- 5=r-x 4=r-- 0=---" \
    "755            |owner rwx, group r-x, others r-x (ปกติสำหรับ script)" \
    "644            |owner rw-, group r--, others r-- (ปกติสำหรับไฟล์ทั่วไป)" \
    "600            |owner rw- เท่านั้น (สำหรับไฟล์ secret เช่น private key)"
  chmod "$1" "$2" && _ok "เปลี่ยน permission: $2 → $1"
}

fm_chown() {
  [[ -z "$1" || -z "$2" ]] && { _err "Usage: fm chown <user> <file>"; return 1; }
  [[ ! -e "$2" ]] && { _err "ไม่พบ: $2"; return 1; }
  _learn_box "fm chown — เปลี่ยนเจ้าของไฟล์" \
    "chown $1 \"$2\"" \
    "chown          |change owner — เปลี่ยนเจ้าของไฟล์" \
    "$1             |ระบุเป็น user หรือ user:group เช่น joe:developers" \
    "(sudo)         |ส่วนใหญ่ต้องใช้ sudo เพราะการ chown ต้องสิทธิ์ root"
  chown "$1" "$2" && _ok "เปลี่ยนเจ้าของ: $2 → $1"
}

fm_mkexec() {
  [[ -z "$1" ]] && { _err "Usage: fm mkexec <file>"; return 1; }
  _learn_box "fm mkexec — ทำให้ไฟล์รันได้" \
    "chmod +x \"$1\"" \
    "chmod +x       |เพิ่ม execute bit ให้ทุก role (owner, group, others)" \
    "(+x vs 755)    |+x เพิ่มบน permission เดิม, 755 ตั้งค่าใหม่ตรงๆ" \
    "(จำเป็น)       |ไฟล์ .sh ต้อง chmod +x ก่อนถึงจะ ./script.sh ได้"
  chmod +x "$1" && _ok "ตั้งค่า +x: $1 สามารถรันได้แล้ว"
}

fm_rmexec() {
  [[ -z "$1" ]] && { _err "Usage: fm rmexec <file>"; return 1; }
  _learn_box "fm rmexec — ถอด execute permission" \
    "chmod -x \"$1\"" \
    "chmod -x       |ลบ execute bit ออกจากทุก role" \
    "(security)     |ใช้เพื่อป้องกัน script ถูกรันโดยไม่ตั้งใจ"
  chmod -x "$1" && _ok "ถอด -x: $1 ไม่สามารถรันได้แล้ว"
}

# ═════════════════════════════════════════════════════════════════
#  DISK & STORAGE
# ═════════════════════════════════════════════════════════════════

fm_df() {
  _learn_box "fm df — ดู disk usage ทุก drive" \
    "df -h" \
    "df             |disk free — แสดง space ที่ใช้/เหลือในแต่ละ filesystem ที่ mount" \
    "-h             |human-readable แสดงเป็น GB/MB แทน 512-byte blocks" \
    "(Mounted on)   |filesystem mount ณ ตำแหน่งใด เช่น / = root, /home = home dir" \
    "(Use%)         |fm color-code: เขียว <70%, เหลือง <90%, แดง >=90%"
  echo ""
  echo -e "  ${LCYAN}💾  Disk Usage Summary${RESET}"
  _sep
  df -h | awk 'NR==1 { printf "  \033[1m%-20s  %-6s  %-6s  %-6s  %-5s  %s\033[0m\n",$1,$2,$3,$4,$5,$6; next }
               NR >1 {
                 used=$5+0
                 color="\033[0;32m"
                 if (used>=90) color="\033[1;31m"
                 else if (used>=70) color="\033[1;33m"
                 printf "  %-20s  %-6s  %-6s  %-6s  %s%-5s\033[0m  %s\n",$1,$2,$3,$4,color,$5,$6
               }'
  echo ""
}

fm_du() {
  local path="${1:-.}"
  _learn_box "fm du — ขนาดแต่ละโฟลเดอร์ย่อย" \
    "du -sh \"$path\"/*/  | sort -rh | head -20" \
    "du             |disk usage — คำนวณขนาดจริงบน disk รวม subdirectory" \
    "-s             |summarize — ยอดรวมต่อโฟลเดอร์ ไม่แตกย่อยทีละไฟล์" \
    "-h             |human-readable" \
    "sort -rh       |r=reverse h=human-numeric (เรียง 1G > 500M > 10K ถูกต้อง)" \
    "head -20       |แสดงแค่ 20 โฟลเดอร์ใหญ่สุด"
  _info "ขนาดโฟลเดอร์ย่อยใน $path :"
  echo ""
  du -sh "$path"/*/ 2>/dev/null | sort -rh | head -20 \
    | awk '{printf "  \033[1;33m%-10s\033[0m  %s\n", $1, $2}'
  echo ""
}

fm_clean() {
  local path="${1:-.}"
  _learn_box "fm clean — ลบไฟล์ temporary/cache" \
    "find \"$path\" -type f \\( -name '*.tmp' -o -name '*.log' -o -name '.DS_Store' -o -name 'Thumbs.db' -o -name '*.cache' \\) -print -delete" \
    "-type f        |ไฟล์เท่านั้น (ไม่ลบโฟลเดอร์)" \
    "\\( ... \\)      |grouping conditions ด้วย parentheses" \
    "-o             |OR — ตรงกับ pattern ใดก็ได้ใน group" \
    "-name '*.tmp'  |wildcard match ชื่อไฟล์ที่ลงท้ายด้วย .tmp" \
    "-print         |แสดงชื่อก่อนลบ (เพื่อ audit ว่าลบอะไรไปบ้าง)" \
    "-delete        |ลบทันที ไม่ผ่าน trash (permanent)"
  _warn "กำลังจะลบไฟล์ tmp/cache ใน: $path"
  _confirm "ยืนยัน?" || { _info "ยกเลิก"; return 0; }
  find "$path" -type f \( -name "*.tmp" -o -name "*.log" -o -name ".DS_Store" \
    -o -name "Thumbs.db" -o -name "*.cache" \) -print -delete 2>/dev/null
  _ok "ล้างไฟล์ชั่วคราวสำเร็จ"
}

FM_TRASH="${HOME}/.fm_trash"

fm_trash() {
  mkdir -p "$FM_TRASH"
  _learn_box "fm trash — ดูไฟล์ใน Trash" \
    "ls -lh \"$FM_TRASH\"" \
    "FM_TRASH       |fm เก็บไฟล์ที่ 'ลบ' ไว้ที่ ~/.fm_trash แทนการลบตาย" \
    "ls -lh         |l=long format, h=human-readable size" \
    "(restore)      |ถ้าอยากคืนไฟล์: fm cp ~/.fm_trash/ชื่อไฟล์ ~/ปลายทาง"
  if [[ -z "$(ls -A "$FM_TRASH")" ]]; then
    _info "Trash ว่างเปล่า 🎉"
  else
    _info "ไฟล์ใน Trash (${FM_TRASH}):"
    echo ""
    ls -lh "$FM_TRASH" | awk 'NR>1 {printf "  \033[0;37m%-10s\033[0m  %s\n", $5, $9}'
    echo ""
  fi
}

fm_emptytrash() {
  mkdir -p "$FM_TRASH"
  _learn_box "fm emptytrash — ล้าง Trash ถาวร" \
    "rm -rf \"${FM_TRASH}\"/*" \
    "rm             |remove" \
    "-r             |recursive — ลบโฟลเดอร์และทุกอย่างข้างใน" \
    "-f             |force — ไม่ถาม ไม่ error ถ้าไฟล์ไม่มี" \
    "/*             |glob: ทุกสิ่งใน FM_TRASH แต่ไม่ลบ folder Trash ตัวเอง" \
    "(ถาวร)         |ย้อนกลับไม่ได้ — fm จึงถามยืนยันก่อนเสมอ"
  if [[ -z "$(ls -A "$FM_TRASH")" ]]; then _info "Trash ว่างอยู่แล้ว"; return 0; fi
  _confirm "ล้าง Trash ถาวร (ย้อนกลับไม่ได้)?" || { _info "ยกเลิก"; return 0; }
  rm -rf "${FM_TRASH:?}"/* && _ok "ล้าง Trash สำเร็จ"
}

# ═════════════════════════════════════════════════════════════════
#  BATCH OPERATIONS
# ═════════════════════════════════════════════════════════════════

fm_bren() {
  local pattern="${1:?Usage: fm bren <old_pattern> <replacement>}"
  local replace="${2:?Usage: fm bren <old_pattern> <replacement>}"
  _learn_box "fm bren — เปลี่ยนชื่อหลายไฟล์พร้อมกัน" \
    "for f in *\"$pattern\"*; do mv \"\$f\" \"\${f//$pattern/$replace}\"; done" \
    "for f in *pat* |glob expansion: shell หา filename ที่มี pattern ก่อน loop" \
    "\${f//pat/rep} |bash string substitution: แทนทุก occurrence ของ pat ด้วย rep" \
    "(preview)      |fm แสดง before→after ก่อนถามยืนยัน ไม่ได้เปลี่ยนทันที"
  _info "Preview การเปลี่ยนชื่อ (pattern='$pattern' → '$replace'):"
  echo ""
  local count=0
  for f in *"$pattern"*; do
    [[ -e "$f" ]] || continue
    local newname="${f//$pattern/$replace}"
    printf "  ${LRED}%-30s${RESET}  →  ${LGREEN}%s${RESET}\n" "$f" "$newname"
    (( count++ ))
  done
  [[ $count -eq 0 ]] && { _warn "ไม่พบไฟล์ที่ตรงกัน"; return 0; }
  echo ""
  _confirm "ยืนยันเปลี่ยนชื่อ $count ไฟล์?" || { _info "ยกเลิก"; return 0; }
  for f in *"$pattern"*; do
    [[ -e "$f" ]] || continue
    mv "$f" "${f//$pattern/$replace}"
  done
  _ok "เปลี่ยนชื่อ $count ไฟล์สำเร็จ"
}

fm_bcp() {
  local dst="${1:?Usage: fm bcp <destination> <file1> <file2> ...}"
  shift
  [[ $# -eq 0 ]] && { _err "ระบุไฟล์ที่จะคัดลอก"; return 1; }
  _learn_box "fm bcp — คัดลอกหลายไฟล์พร้อมกัน" \
    "mkdir -p \"$dst\" && cp -v <files...> \"$dst/\"" \
    "cp             |copy" \
    "-v             |verbose — แสดงทุกไฟล์ที่คัดลอก" \
    "\$@ (args)      |bash รับ argument หลายตัว แล้วส่งต่อให้ cp ทีเดียว" \
    "mkdir -p       |fm สร้าง destination อัตโนมัติถ้ายังไม่มี"
  mkdir -p "$dst"
  _step "คัดลอก $# ไฟล์ → $dst"
  cp -v "$@" "$dst/" && _ok "คัดลอก $# ไฟล์สำเร็จ"
}

fm_bmv() {
  local dst="${1:?Usage: fm bmv <destination> <file1> <file2> ...}"
  shift
  [[ $# -eq 0 ]] && { _err "ระบุไฟล์ที่จะย้าย"; return 1; }
  _learn_box "fm bmv — ย้ายหลายไฟล์พร้อมกัน" \
    "mkdir -p \"$dst\" && mv -v <files...> \"$dst/\"" \
    "mv             |move" \
    "-v             |verbose" \
    "\$@ (args)      |bash ส่ง argument ทุกตัวให้ mv ทีเดียว" \
    "(ยืนยัน)       |fm ถามก่อนย้าย เพราะ mv ย้อนกลับยาก"
  mkdir -p "$dst"
  _confirm "ย้าย $# ไฟล์ → $dst?" || { _info "ยกเลิก"; return 0; }
  mv -v "$@" "$dst/" && _ok "ย้าย $# ไฟล์สำเร็จ"
}

fm_brm() {
  local pattern="${1:?Usage: fm brm <pattern> [path]}"
  local path="${2:-.}"
  _learn_box "fm brm — ลบหลายไฟล์ตาม pattern" \
    "find \"$path\" -maxdepth 1 -name \"*${pattern}*\"  →  rm -v <each>" \
    "find -maxdepth 1|ค้นแค่ชั้นเดียว ไม่ recursive (ปลอดภัยกว่า)" \
    "-name \"*pat*\"  |wildcard match ชื่อไฟล์ที่มี pattern อยู่" \
    "(preview)      |fm แสดงรายการก่อน แล้วถามยืนยัน ไม่ลบทันที" \
    "rm -v          |verbose ลบทีละไฟล์พร้อมแสดงชื่อ"
  _warn "ไฟล์ที่จะถูกลบ (pattern: $pattern):"
  echo ""
  local files=()
  while IFS= read -r f; do
    files+=("$f")
    echo -e "  ${LRED}🗑  $f${RESET}"
  done < <(find "$path" -maxdepth 1 -name "*${pattern}*" 2>/dev/null)
  [[ ${#files[@]} -eq 0 ]] && { _warn "ไม่พบไฟล์ที่ตรงกัน"; return 0; }
  echo ""
  _confirm "ลบ ${#files[@]} ไฟล์?" || { _info "ยกเลิก"; return 0; }
  for f in "${files[@]}"; do rm -v "$f"; done
  _ok "ลบ ${#files[@]} ไฟล์สำเร็จ"
}

fm_sortdir() {
  local src="${1:?Usage: fm sortdir <source_dir> <dest_dir>}"
  local dst="${2:?Usage: fm sortdir <source_dir> <dest_dir>}"
  [[ ! -d "$src" ]] && { _err "ไม่พบโฟลเดอร์ต้นทาง: $src"; return 1; }
  _learn_box "fm sortdir — จัดเรียงไฟล์ตามนามสกุล" \
    "find \"$src\" -maxdepth 1 -type f | while read f; do ext=\${f##*.}; mv \"\$f\" \"$dst/\${ext^^}/\"; done" \
    "\${f##*.}       |bash string op: ตัดทุกอย่างจนถึง . สุดท้าย เหลือแค่ extension" \
    "\${ext^^}       |bash uppercase: แปลง extension เป็นตัวพิมพ์ใหญ่ เช่น jpg→JPG" \
    "mkdir -p       |สร้างโฟลเดอร์ ext อัตโนมัติถ้ายังไม่มี" \
    "(ตัวอย่าง)     |photo.jpg → dst/JPG/photo.jpg, script.sh → dst/SH/script.sh"
  _info "จัดเรียงไฟล์ใน $src ตามนามสกุล → $dst"
  _confirm "ยืนยัน?" || { _info "ยกเลิก"; return 0; }
  find "$src" -maxdepth 1 -type f | while IFS= read -r f; do
    local ext name ext_dir
    name=$(basename "$f")
    ext="${name##*.}"; [[ "$ext" == "$name" ]] && ext="no_ext"
    ext_dir="${dst}/${ext^^}"
    mkdir -p "$ext_dir"
    mv "$f" "$ext_dir/"
    echo -e "  ${GREEN}$name${RESET} → ${LBLUE}${ext^^}/${RESET}"
  done
  _ok "จัดเรียงไฟล์เสร็จสิ้น"
}

fm_datedir() {
  local src="${1:?Usage: fm datedir <source_dir> <dest_dir>}"
  local dst="${2:?Usage: fm datedir <source_dir> <dest_dir>}"
  [[ ! -d "$src" ]] && { _err "ไม่พบ: $src"; return 1; }
  _learn_box "fm datedir — จัดเรียงไฟล์ตามวันที่แก้ไข" \
    "find \"$src\" -maxdepth 1 -type f | while read f; do d=\$(date -r \"\$f\" '+%Y/%m-%b'); mv \"\$f\" \"$dst/\$d/\"; done" \
    "date -r \$f     |อ่าน mtime ของไฟล์แล้วแปลงเป็น format ที่กำหนด" \
    "+%Y/%m-%b      |format: ปี/เดือนตัวเลข-เดือนตัวอักษร เช่น 2025/05-May" \
    "mkdir -p       |สร้างโครงสร้างโฟลเดอร์ปี/เดือน อัตโนมัติ" \
    "(ตัวอย่าง)     |photo.jpg (แก้ไข 1 พ.ค. 2025) → dst/2025/05-May/photo.jpg"
  _info "จัดเรียงไฟล์ใน $src ตามวันที่ → $dst"
  _confirm "ยืนยัน?" || { _info "ยกเลิก"; return 0; }
  find "$src" -maxdepth 1 -type f | while IFS= read -r f; do
    local name date_folder
    name=$(basename "$f")
    date_folder=$(date -r "$f" "+%Y/%m-%b" 2>/dev/null || stat -f '%Sm' -t '%Y/%m-%b' "$f" 2>/dev/null || echo "unknown")
    mkdir -p "${dst}/${date_folder}"
    mv "$f" "${dst}/${date_folder}/"
    echo -e "  ${GREEN}$name${RESET} → ${LBLUE}${date_folder}/${RESET}"
  done
  _ok "จัดเรียงตามวันที่สำเร็จ"
}

# ═════════════════════════════════════════════════════════════════
#  SYNC & REMOTE (3-WORLDS)
# ═════════════════════════════════════════════════════════════════

fm_world() {
  _learn_box "fm world — ตรวจสอบสถานะการเชื่อมต่อระหว่างเครื่อง" \
    "uname -o  +  ping -c 1 \$IP" \
    "uname -o      |ตรวจสอบ OS ปัจจุบัน (Android/Linux/Windows)" \
    "ping          |ทดสอบว่าเครื่องอื่นออนไลน์อยู่หรือไม่ (Latency)" \
    "env vars      |ใช้ค่า IP/USER ที่ตั้งไว้ใน .bashjoe"
  
  local world
  case "$(uname -o 2>/dev/null || uname)" in
    Android*)      world="termux" ;;
    Linux*)        [[ -d /data/data/com.termux ]] && world="termux" || world="wsl" ;;
    *)             world="unknown" ;;
  esac

  echo ""
  echo -e "  ${LCYAN}🌏 Current World:${RESET} ${YELLOW}${world}${RESET}"
  _sep
  printf "  ${DIM}%-12s${RESET}  %s\n" "WSL:"    "${WSL_USER:-user}@${WSL_IP:-localhost}"
  printf "  ${DIM}%-12s${RESET}  %s\n" "Termux:" "${TERMUX_USER:-u0_a331}@${TERMUX_IP:-localhost}"
  printf "  ${DIM}%-12s${RESET}  %s\n" "Windows:" "${WINDOWS_IP:-localhost}"
  echo ""
}

fm_ssh() {
  local target="${1:?Usage: fm ssh <tm|tw|wsl>}"
  shift
  _learn_box "fm ssh — เชื่อมต่อผ่าน Secure Shell" \
    "ssh -p <port> <user>@<ip>" \
    "ssh           |Secure Shell — เข้ารหัสข้อมูลทั้งหมดที่ส่งผ่าน network" \
    "-p <port>     |ระบุ port (Termux ใช้ 8022, Default คือ 22)" \
    "(shortcut)    |fm ssh tm = เข้ามือถือ, fm ssh tw = เข้า Windows"
  
  case "$target" in
    tm)  ssh -p 8022 "${TERMUX_USER}@${TERMUX_IP}" "$@" ;;
    tw)  ssh "${WINDOWS_USER}@${WINDOWS_IP}" "$@" ;;
    wsl) ssh -i ~/.ssh/id_ed25519_wsl -p 22 "${WSL_USER}@${WSL_IP}" "$@" ;;
    *)   _err "ไม่รู้จักเป้าหมาย: $target (ใช้: tm, tw, wsl)" ;;
  esac
}

fm_push() {
  local src="${1:?Usage: fm push <local_path> [remote_dest]}"
  local dst="${2:-.}"
  local current_os=$(uname -o 2>/dev/null || uname)
  local r_user r_ip r_port r_name
  
  if [[ "$current_os" == "Android"* ]]; then
    r_user="$WSL_USER"; r_ip="$WSL_IP"; r_port="22"; r_name="WSL"
  else
    r_user="$TERMUX_USER"; r_ip="$TERMUX_IP"; r_port="8022"; r_name="Termux"
  fi

  _learn_box "fm push — ส่งไฟล์ไป $r_name" \
    "rsync -az --info=progress2 -e 'ssh -p $r_port' \"$src\" \"user@ip:$dst\"" \
    "-a/z/update   |Archive, Compress, และ Update ไฟล์ใหม่กว่า" \
    "-e 'ssh -p'   |ระบุ port ของเครื่องปลายทาง ($r_port)"
  
  _step "Pushing: $src → $r_name:$dst"
  rsync -az --update --info=progress2 -e "ssh -p $r_port" "$src" "${r_user}@${r_ip}:$dst" && _ok "Push สำเร็จ"
}

fm_pull() {
  local src="${1:?Usage: fm pull <remote_path> [local_dest]}"
  local dst="${2:-.}"
  local current_os=$(uname -o 2>/dev/null || uname)
  local r_user r_ip r_port r_name
  
  if [[ "$current_os" == "Android"* ]]; then
    r_user="$WSL_USER"; r_ip="$WSL_IP"; r_port="22"; r_name="WSL"
  else
    r_user="$TERMUX_USER"; r_ip="$TERMUX_IP"; r_port="8022"; r_name="Termux"
  fi

  _learn_box "fm pull — ดึงไฟล์จาก $r_name" \
    "rsync -az --info=progress2 -e 'ssh -p $r_port' \"user@ip:$src\" \"$dst\"" \
    "Pull          |ดึง code ที่แก้ใน $r_name กลับมาที่เครื่องปัจจุบัน"
  
  _step "Pulling: $r_name:$src → $dst"
  rsync -az --update --info=progress2 -e "ssh -p $r_port" "${r_user}@${r_ip}:$src" "$dst" && _ok "Pull สำเร็จ"
}

fm_rls() {
  local path="${1:-~}"
  local current_os=$(uname -o 2>/dev/null || uname)
  local r_user r_ip r_port r_name
  
  if [[ "$current_os" == "Android"* ]]; then
    r_user="$WSL_USER"; r_ip="$WSL_IP"; r_port="22"; r_name="WSL"
  else
    r_user="$TERMUX_USER"; r_ip="$TERMUX_IP"; r_port="8022"; r_name="Termux"
  fi

  _learn_box "fm rls — ดูไฟล์ใน $r_name" \
    "ssh -p $r_port user@ip 'ls -lah $path'" \
    "ssh <cmd>     |รันคำสั่งบนเครื่องปลายทาง ($r_name)"
  
  _info "$r_name Files in $path :"
  echo ""
  ssh -p $r_port "${r_user}@${r_ip}" "ls -lah '$path'"
  echo ""
}

fm_rrun() {
  [[ $# -eq 0 ]] && { _err "Usage: fm rrun <command>"; return 1; }
  local current_os=$(uname -o 2>/dev/null || uname)
  local r_user r_ip r_port r_name
  
  if [[ "$current_os" == "Android"* ]]; then
    r_user="$WSL_USER"; r_ip="$WSL_IP"; r_port="22"; r_name="WSL"
  else
    r_user="$TERMUX_USER"; r_ip="$TERMUX_IP"; r_port="8022"; r_name="Termux"
  fi

  _learn_box "fm rrun — รันคำสั่งบน $r_name" \
    "ssh -p $r_port user@ip \"$*\"" \
    "\"\$*\"          |ส่งคำสั่งทั้งหมดไปรันที่ $r_name"
  
  _step "Remote Run on $r_name: $*"
  ssh -p $r_port "${r_user}@${r_ip}" "$@"
}

# ═════════════════════════════════════════════════════════════════
#  COMPLETION & SHORTHANDS (Integrated from 3-Worlds)
# ═════════════════════════════════════════════════════════════════

_T_CACHE_DIR="/tmp/.termux_completion_cache"
_T_CACHE_TTL=30

_t_remote_paths() {
  local prefix="$1"
  local cache_key; cache_key=$(echo "$prefix" | sed 's|/[^/]*$||; s|[^a-zA-Z0-9]|_|g')
  [[ -z "$cache_key" ]] && cache_key="root"
  local cache_file="$_T_CACHE_DIR/${cache_key}.cache"
  mkdir -p "$_T_CACHE_DIR"

  if [[ -f "$cache_file" ]]; then
    local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    [[ $age -lt $_T_CACHE_TTL ]] && grep "^$prefix" "$cache_file" 2>/dev/null && return
  fi

  local dir; dir=$(dirname "$prefix"); [[ "$dir" == "." ]] && dir="~"
  ssh -p 8022 "${TERMUX_USER}@${TERMUX_IP}" "ls -1dp ${prefix}* 2>/dev/null || ls -1dp ${dir}/ 2>/dev/null" 2>/dev/null | tee "$cache_file"
}

_comp_push() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 2 ]]; then
    mapfile -t COMPREPLY < <(compgen -f -- "$cur")
    [[ ${#COMPREPLY[@]} -eq 1 && -d "${COMPREPLY[0]}" ]] && COMPREPLY[0]+="/"
  elif [[ $COMP_CWORD -eq 3 ]]; then
    mapfile -t COMPREPLY < <(_t_remote_paths "$cur")
  fi
}

_comp_pull() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 2 ]]; then
    mapfile -t COMPREPLY < <(_t_remote_paths "$cur")
  elif [[ $COMP_CWORD -eq 3 ]]; then
    mapfile -t COMPREPLY < <(compgen -f -- "$cur")
    [[ ${#COMPREPLY[@]} -eq 1 && -d "${COMPREPLY[0]}" ]] && COMPREPLY[0]+="/"
  fi
}

# Apply completion to fm push/pull
# Note: Complex completion for subcommands requires a dispatcher.
# For now, we'll keep the direct aliases for better completion experience.
alias push="fm push"
alias pull="fm pull"
complete -o nospace -F _comp_push push
complete -o nospace -F _comp_pull pull

# SSH Shortcuts
alias tm="fm ssh tm"
alias tw="fm ssh tw"
alias swsl="fm ssh wsl"

# Legacy Shorthands (Restored)
alias cpw2t="push"
alias cpt2w="pull"


# ═════════════════════════════════════════════════════════════════
#  MAIN DISPATCHER
# ═════════════════════════════════════════════════════════════════
fm() {
  local cmd="${1:-help}"
  shift 2>/dev/null
  case "$cmd" in
    ls)          fm_ls "$@"         ;;
    lsa)         fm_lsa "$@"        ;;
    tree)        fm_tree "$@"       ;;
    goto)        fm_goto "$@"       ;;
    back)        fm_back            ;;
    home)        fm_home            ;;
    pwd)         fm_pwd             ;;
    cp)          fm_cp "$@"         ;;
    mv)          fm_mv "$@"         ;;
    rm)          fm_rm "$@"         ;;
    rn)          fm_rn "$@"         ;;
    mk)          fm_mk "$@"         ;;
    mkdir)       fm_mkdir "$@"      ;;
    touch)       fm_touch "$@"      ;;
    link)        fm_link "$@"       ;;
    find)        fm_find "$@"       ;;
    grep)        fm_grep "$@"       ;;
    findext)     fm_findext "$@"    ;;
    findsize)    fm_findsize "$@"   ;;
    info)        fm_info "$@"       ;;
    size)        fm_size "$@"       ;;
    recent)      fm_recent "$@"     ;;
    big)         fm_big "$@"        ;;
    dup)         fm_dup "$@"        ;;
    zip)         fm_zip "$@"        ;;
    unzip)       fm_unzip "$@"      ;;
    tar)         fm_tar "$@"        ;;
    untar)       fm_untar "$@"      ;;
    ziplist)     fm_ziplist "$@"    ;;
    perm)        fm_perm "$@"       ;;
    chmod)       fm_chmod "$@"      ;;
    chown)       fm_chown "$@"      ;;
    mkexec)      fm_mkexec "$@"     ;;
    rmexec)      fm_rmexec "$@"     ;;
    df)          fm_df              ;;
    du)          fm_du "$@"         ;;
    clean)       fm_clean "$@"      ;;
    trash)       fm_trash           ;;
    emptytrash)  fm_emptytrash      ;;
    bren)        fm_bren "$@"       ;;
    bcp)         fm_bcp "$@"        ;;
    bmv)         fm_bmv "$@"        ;;
    brm)         fm_brm "$@"        ;;
    sortdir)     fm_sortdir "$@"    ;;
    datedir)     fm_datedir "$@"    ;;
    world)       fm_world           ;;
    ssh)         fm_ssh "$@"        ;;
    push)        fm_push "$@"       ;;
    pull)        fm_pull "$@"       ;;
    rls)         fm_rls "$@"        ;;
    rrun)        fm_rrun "$@"       ;;
    learn)       fm_learn "$@"      ;;
    help|--help|-h|"") fm_help "$@" ;;
    *)
      _err "ไม่รู้จักคำสั่ง: $cmd"
      echo -e "  ${DIM}พิมพ์ ${RESET}${CYAN}fm help${RESET}${DIM} เพื่อดูรายการคำสั่งทั้งหมด${RESET}"
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────
# AUTO-WELCOME when sourced
# ─────────────────────────────────────────────────────────────────

_fm_banner() {
  echo -e ""
  echo -e "${LCYAN}  ███████╗██╗██╗     ███████╗███╗   ███╗ ██████╗ ██████╗ ${RESET}"
  echo -e "${LCYAN}  ██╔════╝██║██║     ██╔════╝████╗ ████║██╔════╝ ██╔══██╗${RESET}"
  echo -e "${LCYAN}  █████╗  ██║██║     █████╗  ██╔████╔██║██║  ███╗██████╔╝${RESET}"
  echo -e "${LCYAN}  ██╔══╝  ██║██║     ██╔══╝  ██║╚██╔╝██║██║   ██║██╔══██╗${RESET}"
  echo -e "${LCYAN}  ██║     ██║███████╗███████╗██║ ╚═╝ ██║╚██████╔╝██║  ██║${RESET}"
  echo -e "${LCYAN}  ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝${RESET}"
  echo -e "  ${WHITE}${BOLD}File Manager CLI — v3.0${RESET} | ${DIM}Personal Command Center${RESET}"
  echo -e "  ${DIM}───────────────────────────────────────────────────────────────────${RESET}"
  echo -e "  ${YELLOW}🚀 Quick Start:${RESET}"
  echo -e "    ${CYAN}fm help${RESET}       ${GRAY}→  แสดงคำสั่งทั้งหมด (Category-based help)${RESET}"
  echo -e "    ${CYAN}fm learn on${RESET}   ${GRAY}→  เปิด Learn Mode (เพื่อดูคำสั่งจริงขณะรัน)${RESET}"
  echo -e "    ${CYAN}fm world${RESET}      ${GRAY}→  ตรวจสอบ IP และสถานะเครื่องอื่น (3-Worlds)${RESET}"
  echo -e "  ${DIM}───────────────────────────────────────────────────────────────────${RESET}"
  echo -e "  ${LGREEN}✅ File Manager loaded and ready to serve, Captain!${RESET}"
  echo -e ""
}

# Run the banner

