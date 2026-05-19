
# ═════════════════════════════════════════════════════════════════
#
#   ██╗  ██╗███████╗███╗   ███╗
#   ╚██╗██╔╝██╔════╝████╗ ████║
#    ╚███╔╝ █████╗  ██╔████╔██║
#    ██╔██╗ ██╔══╝  ██║╚██╔╝██║
#   ██╔╝ ██╗██║     ██║ ╚═╝ ██║
#   ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝
#   Cross-Machine File Manager — v1.0
#   วางต่อท้าย filemanager.sh แล้ว source ไฟล์เดิมตามปกติ
#
#   Usage: xfm help
#          xfm status
#          xfm ls win
#          xfm cp win:/Users/User/doc.txt tx:~/doc.txt
#          xfm sync wsl:~/projects deb:~/projects
#
# ═════════════════════════════════════════════════════════════════

_xfm_banner() {
  echo -e ""
  echo -e "${LCYAN}  ██╗  ██╗███████╗███╗   ███╗${RESET}"
  echo -e "${LCYAN}  ╚██╗██╔╝██╔════╝████╗ ████║${RESET}"
  echo -e "${LCYAN}   ╚███╔╝ █████╗  ██╔████╔██║${RESET}"
  echo -e "${LCYAN}   ██╔██╗ ██╔══╝  ██║╚██╔╝██║${RESET}"
  echo -e "${LCYAN}  ██╔╝ ██╗██║     ██║ ╚═╝ ██║${RESET}"
  echo -e "${LCYAN}  ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝${RESET}"

  echo -e "  ${WHITE}${BOLD}Cross-Machine File Manager — v1.0${RESET}"
  echo -e "  ${DIM}Universal File Transport Layer for 3-World Infrastructure${RESET}"

  echo -e "  ${DIM}───────────────────────────────────────────────────────────────────${RESET}"

  echo -e "  ${YELLOW}🚀 Quick Start:${RESET}"
  echo -e "    ${CYAN}xfm help${RESET}         ${GRAY}→  แสดงคำสั่งทั้งหมด${RESET}"
  echo -e "    ${CYAN}xfm status${RESET}       ${GRAY}→  ตรวจสอบสถานะทุกเครื่อง${RESET}"
  echo -e "    ${CYAN}xfm ls win${RESET}       ${GRAY}→  ดูไฟล์ฝั่ง Windows${RESET}"
  echo -e "    ${CYAN}xfm cp tx:~/a wsl:~/b${RESET} ${GRAY}→  copy ข้ามโลก${RESET}"
  echo -e "    ${CYAN}xfm sync wsl:~/p deb:~/p${RESET} ${GRAY}→  sync project ข้ามเครื่อง${RESET}"

  echo -e "  ${DIM}───────────────────────────────────────────────────────────────────${RESET}"

  echo -e "  ${LGREEN}✅ XFM loaded successfully. Cross-world bridge established.${RESET}"
  echo -e ""
}


# ─────────────────────────────────────────────────────────────────
# MACHINE CONFIG — แก้ตรงนี้ถ้า IP/User เปลี่ยน
# ─────────────────────────────────────────────────────────────────
xfm_WIN_IP="${WINDOWS_IP:-100.69.181.45}"
xfm_WIN_USER="${WINDOWS_USER:-User}"
xfm_WIN_PORT="22"

xfm_WSL_IP="${WSL_IP:-100.80.195.120}"
xfm_WSL_USER="${WSL_USER:-usercivenz}"
xfm_WSL_PORT="22"

xfm_tx_IP="${TERMUX_IP:-100.110.26.16}"
xfm_tx_USER="${TERMUX_USER:-u0_a331}"
xfm_tx_PORT="${TERMUX_PORT:-8022}"

xfm_DEB_IP="${DEBAIN_IP:-100.110.26.16}"
xfm_DEB_USER="${DEBAIN_USER:-flux}"
xfm_DEB_PORT="${DEBAIN_PORT:-9022}"

# ─────────────────────────────────────────────────────────────────
# MACHINE RESOLVER HELPERS
# ─────────────────────────────────────────────────────────────────

# รับ nickname → คืน IP
_xfm_host() {
  case "${1,,}" in
    win|windows) echo "$xfm_WIN_IP"  ;;
    wsl)         echo "$xfm_WSL_IP"  ;;
    tx|termux)   echo "$xfm_tx_IP"   ;;
    deb|debian)  echo "$xfm_DEB_IP"  ;;
    local|.)     echo "localhost"     ;;
    *) return 1 ;;
  esac
}

# รับ nickname → คืน username
_xfm_user() {
  case "${1,,}" in
    win|windows) echo "$xfm_WIN_USER" ;;
    wsl)         echo "$xfm_WSL_USER" ;;
    tx|termux)   echo "$xfm_tx_USER"  ;;
    deb|debian)  echo "$xfm_DEB_USER" ;;
    local|.)     echo "$USER"          ;;
    *) return 1 ;;
  esac
}

# รับ nickname → คืน SSH port
_xfm_port() {
  case "${1,,}" in
    win|windows) echo "$xfm_WIN_PORT" ;;
    wsl)         echo "$xfm_WSL_PORT" ;;
    tx|termux)   echo "$xfm_tx_PORT"  ;;
    deb|debian)  echo "$xfm_DEB_PORT" ;;
    local|.)     echo ""               ;;
    *) return 1 ;;
  esac
}

# รับ nickname → คืนชื่อแสดงผลสวยๆ
_xfm_label() {
  case "${1,,}" in
    win|windows) echo -e "${LBLUE}🖥️  win${RESET}"    ;;
    wsl)         echo -e "${LGREEN}🐧  wsl${RESET}"   ;;
    tx|termux)   echo -e "${YELLOW}📱  tx${RESET}"    ;;
    deb|debian)  echo -e "${LCYAN}🔷  deb${RESET}"   ;;
    local|.)     echo -e "${WHITE}💻  local${RESET}"  ;;
    *)           echo -e "${GRAY}❓  $1${RESET}"      ;;
  esac
}

# Validate machine name
_xfm_valid() {
  case "${1,,}" in
    win|windows|wsl|tx|termux|deb|debian|local|.) return 0 ;;
    *) return 1 ;;
  esac
}

# Parse "machine:path" หรือ "path" (ไม่มี machine = local)
# Usage: machine=$(_xfm_mach "$arg")  path=$(_xfm_path "$arg")
_xfm_mach() {
  if [[ "$1" == *":"* && ! "${1%%:*}" == "/"* ]]; then
    echo "${1%%:*}"
  else
    echo "local"
  fi
}
_xfm_path() {
  if [[ "$1" == *":"* && ! "${1%%:*}" == "/"* ]]; then
    echo "${1#*:}"
  else
    echo "$1"
  fi
}

# Build SSH connection string สำหรับ display
_xfm_conn_str() {
  local m="$1"
  local host user port
  host=$(_xfm_host "$m")
  user=$(_xfm_user "$m")
  port=$(_xfm_port "$m")
  [[ -n "$port" ]] && echo "$user@$host:$port" || echo "$user@$host"
}

# ─────────────────────────────────────────────────────────────────
# SSH / SCP / RSYNC WRAPPERS
# ─────────────────────────────────────────────────────────────────

# รัน command บน remote machine
# Usage: _xfm_ssh <machine> <command>
_xfm_ssh() {
  local machine="$1"; shift
  local host user port
  host=$(_xfm_host "$machine") || { _err "ไม่รู้จัก machine: $machine"; return 1; }
  user=$(_xfm_user "$machine")
  port=$(_xfm_port "$machine")
  if [[ -n "$port" ]]; then
    ssh -p "$port" -o ConnectTimeout=8 -o BatchMode=yes "$user@$host" "$@"
  else
    ssh -o ConnectTimeout=8 -o BatchMode=yes "$user@$host" "$@"
  fi
}

# rsync: local → remote
# Usage: _xfm_push <local_src> <machine> <remote_dst>
_xfm_push() {
  local src="$1" machine="$2" dst="$3"
  local host user port
  host=$(_xfm_host "$machine")
  user=$(_xfm_user "$machine")
  port=$(_xfm_port "$machine")
  local ssh_opt="-o ConnectTimeout=8 -o BatchMode=yes"
  [[ -n "$port" ]] && ssh_opt="$ssh_opt -p $port"
  rsync -avz --progress -e "ssh $ssh_opt" "$src" "$user@$host:$dst"
}

# rsync: remote → local
# Usage: _xfm_pull <machine> <remote_src> <local_dst>
_xfm_pull() {
  local machine="$1" src="$2" dst="$3"
  local host user port
  host=$(_xfm_host "$machine")
  user=$(_xfm_user "$machine")
  port=$(_xfm_port "$machine")
  local ssh_opt="-o ConnectTimeout=8 -o BatchMode=yes"
  [[ -n "$port" ]] && ssh_opt="$ssh_opt -p $port"
  rsync -avz --progress -e "ssh $ssh_opt" "$user@$host:$src" "$dst"
}

# Check ว่า machine online ไหม คืน latency ms หรือ -1 ถ้า offline
_xfm_ping() {
  local machine="$1"
  local host; host=$(_xfm_host "$machine") || { echo "-1"; return; }
  local t0 t1 ms
  t0=$(date +%s%N 2>/dev/null || echo 0)
  if ssh -p "$(_xfm_port "$machine")" \
       -o ConnectTimeout=5 \
       -o BatchMode=yes \
       -o StrictHostKeyChecking=no \
       "$(_xfm_user "$machine")@$host" "echo ok" &>/dev/null; then
    t1=$(date +%s%N 2>/dev/null || echo 0)
    echo $(( (t1 - t0) / 1000000 ))
  else
    echo "-1"
  fi
}

# ─────────────────────────────────────────────────────────────────
# xfm HELP
# ─────────────────────────────────────────────────────────────────
xfm_help() {
  echo ""
  echo -e "${LCYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${LCYAN}║${RESET}  ${BOLD}${WHITE}🌐  xfm — Cross-Machine File Manager  v1.0${RESET}                    ${LCYAN}║${RESET}"
  echo -e "${LCYAN}║${RESET}  ${DIM}4 มิติ: win │ wsl │ tx (Termux) │ deb (Debian)${RESET}             ${LCYAN}║${RESET}"
  echo -e "${LCYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"

  echo ""
  echo -e "  ${LMAGENTA}🏷️   MACHINE NICKNAMES${RESET}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  printf "  ${BOLD}%-10s${RESET}  ${CYAN}%-22s${RESET}  ${DIM}%-20s${RESET}  %s\n" "ALIAS" "USER@IP" "PORT" "MACHINE"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  printf "  ${LBLUE}%-10s${RESET}  ${GRAY}%-22s${RESET}  ${DIM}%-20s${RESET}  %s\n" \
    "win" "$xfm_WIN_USER@$xfm_WIN_IP" "$xfm_WIN_PORT" "🖥️  Windows"
  printf "  ${LGREEN}%-10s${RESET}  ${GRAY}%-22s${RESET}  ${DIM}%-20s${RESET}  %s\n" \
    "wsl" "$xfm_WSL_USER@$xfm_WSL_IP" "$xfm_WSL_PORT" "🐧  WSL"
  printf "  ${YELLOW}%-10s${RESET}  ${GRAY}%-22s${RESET}  ${DIM}%-20s${RESET}  %s\n" \
    "tx" "$xfm_tx_USER@$xfm_tx_IP" "$xfm_tx_PORT" "📱  Termux (Android)"
  printf "  ${LCYAN}%-10s${RESET}  ${GRAY}%-22s${RESET}  ${DIM}%-20s${RESET}  %s\n" \
    "deb" "$xfm_DEB_USER@$xfm_DEB_IP" "$xfm_DEB_PORT" "🔷  Debian (proot)"
  printf "  ${WHITE}%-10s${RESET}  ${GRAY}%-22s${RESET}  ${DIM}%-20s${RESET}  %s\n" \
    "local / ." "$(whoami)@localhost" "-" "💻  เครื่องนี้"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "  ${YELLOW}📡  COMMANDS${RESET}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  printf "  ${BOLD}%-22s${RESET}  ${CYAN}%-34s${RESET}  %s\n" "COMMAND" "SYNTAX" "DESCRIPTION"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm status"  "xfm status"                        "ping ทุกเครื่อง + disk summary"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm ls"      "xfm ls <machine> [path]"           "แสดงไฟล์บน remote"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm cp"      "xfm cp <src> <dst>"                "copy ข้ามเครื่อง (any→any)"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm mv"      "xfm mv <src> <dst>"                "ย้ายข้ามเครื่อง (cp + rm src)"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm rm"      "xfm rm <machine:path>"             "ลบไฟล์บน remote (ถามยืนยัน)"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm mkdir"   "xfm mkdir <machine:path>"          "สร้างโฟลเดอร์บน remote"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm info"    "xfm info <machine:path>"           "รายละเอียดไฟล์บน remote"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm df"      "xfm df [machine|all]"              "disk usage (ทีละเครื่อง หรือทุกเครื่อง)"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm du"      "xfm du <machine:path>"             "ขนาดโฟลเดอร์ย่อยบน remote"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm find"    "xfm find <machine> <name> [path]"  "ค้นหาไฟล์บน remote"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm sync"    "xfm sync <src> <dst>"              "rsync สองทิศทาง (any→any)"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm push"    "xfm push <local_path> <machine:dst>" "local → remote (shorthand)"
  printf "  ${LGREEN}%-22s${RESET}  ${GRAY}%-34s${RESET}  %s\n" "xfm pull"    "xfm pull <machine:src> [local_dst]"  "remote → local (shorthand)"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "  ${DIM}┌──────────────────────────────────────────────────────────────────┐${RESET}"
  echo -e "  ${DIM}│${RESET}  ${BOLD}Syntax:${RESET} ${LCYAN}machine:path${RESET}  เช่น ${YELLOW}tx:~/storage${RESET}  ${LBLUE}win:/Users/User/doc.txt${RESET}   ${DIM}│${RESET}"
  echo -e "  ${DIM}│${RESET}  ไม่ใส่ machine = local  เช่น ${WHITE}~/myfile.txt${RESET}                    ${DIM}│${RESET}"
  echo -e "  ${DIM}│${RESET}  ${ORANGE}📚 Learn Mode:${RESET} ${CYAN}fm learn on${RESET} เพื่อดูคำสั่งจริงทุกครั้ง            ${DIM}│${RESET}"
  echo -e "  ${DIM}└──────────────────────────────────────────────────────────────────┘${RESET}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────
# xfm STATUS — ping ทุกเครื่อง พร้อม disk summary
# ─────────────────────────────────────────────────────────────────
xfm_status() {
  _learn_box "xfm status — ตรวจสถานะทุก machine" \
    "ssh -o ConnectTimeout=5 -o BatchMode=yes user@host 'df -h / | tail -1'" \
    "-o ConnectTimeout=5  |timeout 5 วิ ถ้าไม่ตอบ = offline" \
    "-o BatchMode=yes     |ไม่ถาม password (ใช้ SSH key เท่านั้น)" \
    "df -h / | tail -1    |ดู disk usage ที่ / แค่บรรทัดสุดท้าย" \
    "(parallel)           |xfm ping ทุกเครื่องพร้อมกันด้วย background job &"

  echo ""
  echo -e "  ${LCYAN}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "  ${LCYAN}║${RESET}  ${BOLD}🌐  Cross-Machine Status${RESET}                                     ${LCYAN}║${RESET}"
  echo -e "  ${LCYAN}╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  printf "  ${BOLD}%-6s  %-22s  %-6s  %-8s  %-10s  %s${RESET}\n" \
    "NAME" "CONNECTION" "PORT" "LATENCY" "DISK USE" "STATUS"
  _sep

  local machines=("win" "wsl" "tx" "deb")
  for m in "${machines[@]}"; do
    local host user port label conn_str
    host=$(_xfm_host "$m")
    user=$(_xfm_user "$m")
    port=$(_xfm_port "$m")
    conn_str="$user@$host"
    [[ -n "$port" ]] && port_disp=":$port" || port_disp=":22"

    # ping via SSH
    local ms; ms=$(_xfm_ping "$m")

    if [[ "$ms" -ge 0 ]] 2>/dev/null; then
      # get disk usage
      local disk
      disk=$(_xfm_ssh "$m" "df -h / 2>/dev/null | tail -1 | awk '{print \$5}'" 2>/dev/null || echo "?")
      local disk_num="${disk//%/}"
      local disk_color="${LGREEN}"
      (( disk_num >= 90 )) 2>/dev/null && disk_color="${LRED}"
      (( disk_num >= 70 && disk_num < 90 )) 2>/dev/null && disk_color="${YELLOW}"

      printf "  $(_xfm_label "$m")   ${GRAY}%-22s${RESET}  ${DIM}%-6s${RESET}  ${LGREEN}%-8s${RESET}  ${disk_color}%-10s${RESET}  ${LGREEN}✔ online${RESET}\n" \
        "$conn_str" "$port_disp" "${ms}ms" "$disk"
    else
      printf "  $(_xfm_label "$m")   ${GRAY}%-22s${RESET}  ${DIM}%-6s${RESET}  ${DIM}%-8s${RESET}  ${DIM}%-10s${RESET}  ${LRED}✘ offline${RESET}\n" \
        "$conn_str" "$port_disp" "—" "—"
    fi
  done

  echo ""
}

# ─────────────────────────────────────────────────────────────────
# xfm LS — แสดงไฟล์บน remote
# ─────────────────────────────────────────────────────────────────
xfm_ls() {
  local machine="${1:?Usage: xfm ls <machine> [path]}"
  local path="${2:-~}"
  _xfm_valid "$machine" || { _err "ไม่รู้จัก machine: $machine  (win|wsl|tx|deb|local)"; return 1; }

  _learn_box "xfm ls — แสดงไฟล์บน remote" \
    "ssh -p <port> user@host 'ls -lAh --color=never \"$path\"'" \
    "ssh            |เชื่อมต่อ remote แล้วรัน command" \
    "-p <port>      |port ที่ตั้งไว้ตาม machine (tx=8022, deb=9022, win/wsl=22)" \
    "ls -lAh        |l=long format A=all incl. dotfiles h=human-readable size" \
    "--color=never  |ปิดสี ls เพราะ xfm จะจัด format เอง"

  echo ""
  echo -e "  $(_xfm_label "$machine")  ${LCYAN}📂  $path${RESET}"
  _sep

  if [[ "${machine,,}" == "local" || "${machine,,}" == "." ]]; then
    ls -lAh --color=always "$path" 2>/dev/null || _err "ไม่พบ path: $path"
  else
    _xfm_ssh "$machine" \
      "ls -lAh --color=never \"$path\" 2>/dev/null || echo 'ERROR: path not found'" \
      | while IFS= read -r line; do
          if [[ "$line" == total* ]]; then
            echo -e "  ${DIM}$line${RESET}"
          elif [[ "$line" == d* ]]; then
            echo -e "  ${LBLUE}$line${RESET}"
          elif [[ "$line" == l* ]]; then
            echo -e "  ${CYAN}$line${RESET}"
          elif [[ "$line" == *x* ]]; then
            echo -e "  ${LGREEN}$line${RESET}"
          elif [[ "$line" == ERROR* ]]; then
            echo -e "  ${LRED}$line${RESET}"
          else
            echo -e "  ${WHITE}$line${RESET}"
          fi
        done
  fi
  echo ""
}

# ─────────────────────────────────────────────────────────────────
# xfm CP — copy ข้ามเครื่อง (any → any)
# ─────────────────────────────────────────────────────────────────
xfm_cp() {
  local src_arg="${1:?Usage: xfm cp <src> <dst>  ex: xfm cp win:/file.txt tx:~/}"
  local dst_arg="${2:?Usage: xfm cp <src> <dst>}"

  local src_m src_p dst_m dst_p
  src_m=$(_xfm_mach "$src_arg"); src_p=$(_xfm_path "$src_arg")
  dst_m=$(_xfm_mach "$dst_arg"); dst_p=$(_xfm_path "$dst_arg")

  # ── case 1: same machine ──────────────────────────────────────
  if [[ "${src_m,,}" == "${dst_m,,}" ]]; then
    _learn_box "xfm cp — copy บน machine เดียวกัน ($src_m)" \
      "ssh -p <port> user@host 'cp -rv \"$src_p\" \"$dst_p\"'" \
      "cp -rv         |copy recursive + verbose บน remote via SSH" \
      "(same machine) |src/dst อยู่เครื่องเดียวกัน ไม่ต้องส่งไฟล์ข้าม network"
    _step "copy บน $src_m: $src_p → $dst_p"
    _xfm_ssh "$src_m" "cp -rv \"$src_p\" \"$dst_p\"" && _ok "copy สำเร็จ"
    return
  fi

  # ── case 2: local → remote ────────────────────────────────────
  if [[ "${src_m,,}" == "local" || "${src_m,,}" == "." ]]; then
    _learn_box "xfm cp — local → remote ($dst_m)" \
      "rsync -avz --progress -e 'ssh -p <port>' \"$src_p\" user@host:\"$dst_p\"" \
      "rsync -avz     |a=archive z=compress v=verbose" \
      "--progress     |แสดง progress bar ระหว่าง transfer" \
      "-e 'ssh -p N'  |บอก rsync ให้ใช้ ssh port ที่กำหนด" \
      "user@host:dst  |รูปแบบ remote path ของ rsync"
    _step "push: local:$src_p  →  $dst_m:$dst_p"
    _xfm_push "$src_p" "$dst_m" "$dst_p" && _ok "copy สำเร็จ"
    return
  fi

  # ── case 3: remote → local ────────────────────────────────────
  if [[ "${dst_m,,}" == "local" || "${dst_m,,}" == "." ]]; then
    _learn_box "xfm cp — remote ($src_m) → local" \
      "rsync -avz --progress -e 'ssh -p <port>' user@host:\"$src_p\" \"$dst_p\"" \
      "rsync          |pull mode: remote host อยู่ฝั่ง source" \
      "(pull)         |rsync ดึงไฟล์จาก remote มาไว้ local"
    _step "pull: $src_m:$src_p  →  local:$dst_p"
    _xfm_pull "$src_m" "$src_p" "$dst_p" && _ok "copy สำเร็จ"
    return
  fi

  # ── case 4: remote → remote (route ผ่าน local) ───────────────
  _learn_box "xfm cp — remote→remote ผ่าน local ($src_m → $dst_m)" \
    "rsync pull $src_m:$src_p → /tmp/xfm_relay/  then  rsync push → $dst_m:$dst_p" \
    "step 1: pull    |ดึงจาก $src_m มาไว้ /tmp/xfm_relay/ ก่อน" \
    "step 2: push    |ส่งจาก /tmp/xfm_relay/ ไปยัง $dst_m" \
    "step 3: cleanup |ลบ temp dir หลัง transfer สำเร็จ" \
    "(rsync limit)   |rsync ไม่รองรับ remote-to-remote โดยตรง จึงต้อง relay ผ่าน local"

  local relay_dir; relay_dir=$(mktemp -d /tmp/xfm_relay_XXXXXX)
  trap "rm -rf '$relay_dir'" RETURN

  _step "relay: $src_m:$src_p  →  [local relay]  →  $dst_m:$dst_p"

  _info "Step 1/3 — pull จาก $src_m ..."
  _xfm_pull "$src_m" "$src_p" "$relay_dir/" || { _err "pull จาก $src_m ล้มเหลว"; return 1; }

  _info "Step 2/3 — push ไปยัง $dst_m ..."
  _xfm_push "$relay_dir/" "$dst_m" "$dst_p" || { _err "push ไปยัง $dst_m ล้มเหลว"; return 1; }

  _info "Step 3/3 — cleanup relay dir ..."
  rm -rf "$relay_dir"

  _ok "remote→remote copy สำเร็จ ($src_m → $dst_m)"
}

# ─────────────────────────────────────────────────────────────────
# xfm MV — ย้ายข้ามเครื่อง (cp + rm src)
# ─────────────────────────────────────────────────────────────────
xfm_mv() {
  local src_arg="${1:?Usage: xfm mv <src> <dst>}"
  local dst_arg="${2:?Usage: xfm mv <src> <dst>}"
  local src_m; src_m=$(_xfm_mach "$src_arg")
  local src_p; src_p=$(_xfm_path "$src_arg")

  _learn_box "xfm mv — ย้ายข้ามเครื่อง" \
    "xfm cp <src> <dst>  &&  ssh user@src_host 'rm -rf \"$src_p\"'" \
    "xfm cp         |ทำ copy ก่อน (ทุก case เหมือนกัน)" \
    "rm -rf src     |หลัง copy สำเร็จ ถึงจะลบ source (safe: copy first)" \
    "(ยืนยัน)       |xfm mv ถามยืนยันก่อนเสมอ เพราะลบ source ย้อนกลับไม่ได้"

  _warn "ย้าย: $src_arg → $dst_arg"
  _warn "source จะถูกลบหลัง copy สำเร็จ"
  _confirm "ยืนยัน?" || { _info "ยกเลิก"; return 0; }

  xfm_cp "$src_arg" "$dst_arg" || { _err "copy ล้มเหลว — source ยังอยู่ครบ"; return 1; }

  _info "ลบ source: $src_m:$src_p ..."
  if [[ "${src_m,,}" == "local" || "${src_m,,}" == "." ]]; then
    rm -rf "$src_p" && _ok "ลบ source สำเร็จ"
  else
    _xfm_ssh "$src_m" "rm -rf \"$src_p\"" && _ok "ลบ source บน $src_m สำเร็จ"
  fi
}

# ─────────────────────────────────────────────────────────────────
# xfm RM — ลบไฟล์บน remote
# ─────────────────────────────────────────────────────────────────
xfm_rm() {
  local arg="${1:?Usage: xfm rm <machine:path>}"
  local machine path
  machine=$(_xfm_mach "$arg"); path=$(_xfm_path "$arg")
  _xfm_valid "$machine" || { _err "ไม่รู้จัก machine: $machine"; return 1; }

  _learn_box "xfm rm — ลบไฟล์บน remote" \
    "ssh -p <port> user@host 'rm -rv \"$path\"'" \
    "rm -rv         |recursive + verbose ลบ remote via SSH" \
    "(permanent)    |ลบถาวร ไม่มี trash บน remote — ต้องระวัง!" \
    "(ยืนยัน)       |xfm rm ถามยืนยันก่อนเสมอ"

  _warn "กำลังจะลบบน $(_xfm_label "$machine"): $path"
  _confirm "ยืนยันการลบบน remote?" || { _info "ยกเลิก"; return 0; }

  if [[ "${machine,,}" == "local" || "${machine,,}" == "." ]]; then
    rm -rv "$path" && _ok "ลบสำเร็จ"
  else
    _xfm_ssh "$machine" "rm -rv \"$path\"" && _ok "ลบสำเร็จบน $machine"
  fi
}

# ─────────────────────────────────────────────────────────────────
# xfm MKDIR — สร้างโฟลเดอร์บน remote
# ─────────────────────────────────────────────────────────────────
xfm_mkdir() {
  local arg="${1:?Usage: xfm mkdir <machine:path>}"
  local machine path
  machine=$(_xfm_mach "$arg"); path=$(_xfm_path "$arg")
  _xfm_valid "$machine" || { _err "ไม่รู้จัก machine: $machine"; return 1; }

  _learn_box "xfm mkdir — สร้างโฟลเดอร์บน remote" \
    "ssh -p <port> user@host 'mkdir -pv \"$path\"'" \
    "mkdir -pv      |p=สร้าง parent อัตโนมัติ v=verbose" \
    "ssh ... cmd    |ส่ง command ไปรันบน remote แล้วดู output กลับมา"

  if [[ "${machine,,}" == "local" || "${machine,,}" == "." ]]; then
    mkdir -pv "$path" && _ok "สร้างโฟลเดอร์สำเร็จ"
  else
    _xfm_ssh "$machine" "mkdir -pv \"$path\"" && _ok "สร้างโฟลเดอร์สำเร็จบน $machine"
  fi
}

# ─────────────────────────────────────────────────────────────────
# xfm INFO — รายละเอียดไฟล์บน remote
# ─────────────────────────────────────────────────────────────────
xfm_info() {
  local arg="${1:?Usage: xfm info <machine:path>}"
  local machine path
  machine=$(_xfm_mach "$arg"); path=$(_xfm_path "$arg")
  _xfm_valid "$machine" || { _err "ไม่รู้จัก machine: $machine"; return 1; }

  _learn_box "xfm info — รายละเอียดไฟล์บน remote" \
    "ssh user@host 'stat \"$path\"; file -b \"$path\"; wc -lw \"$path\"'" \
    "stat           |อ่าน metadata จาก inode: size, perm, owner, timestamps" \
    "file -b        |detect file type จาก magic bytes" \
    "wc -lw         |นับ lines และ words (ถ้าเป็น text file)" \
    "(all-in-one)   |รัน 3 commands พร้อมกันใน ssh session เดียว ประหยัด latency"

  echo ""
  echo -e "  $(_xfm_label "$machine")  ${LCYAN}📄  $path${RESET}"
  _sep

  local remote_cmd='
    f="'"$path"'"
    echo "=STAT="
    stat "$f" 2>/dev/null || echo "stat: not found"
    echo "=FILE="
    file -b "$f" 2>/dev/null || echo "unknown"
    echo "=WC="
    wc -lw "$f" 2>/dev/null || echo "n/a"
  '

  if [[ "${machine,,}" == "local" || "${machine,,}" == "." ]]; then
    bash -c "$remote_cmd" 2>/dev/null
  else
    _xfm_ssh "$machine" "$remote_cmd" 2>/dev/null \
      | awk '
          /^=STAT=/ { section="stat"; next }
          /^=FILE=/ { section="file"; next }
          /^=WC=/   { section="wc";   next }
          section=="stat" { print "  \033[2m" $0 "\033[0m" }
          section=="file" { print "  \033[1;36mType:\033[0m  " $0 }
          section=="wc"   { print "  \033[1;36mLines/Words:\033[0m  " $0 }
        '
  fi
  echo ""
}

# ─────────────────────────────────────────────────────────────────
# xfm DF — disk usage (ทีละเครื่อง หรือทุกเครื่องพร้อมกัน)
# ─────────────────────────────────────────────────────────────────
xfm_df() {
  local target="${1:-all}"

  _learn_box "xfm df — disk usage บน remote" \
    "ssh user@host 'df -h'" \
    "df -h          |disk free human-readable — แสดง space ทุก filesystem" \
    "(all)          |xfm loop ทุก machine และรัน df พร้อมกัน (background &)" \
    "(parallel)     |ส่ง SSH request ทุกเครื่องพร้อมกัน แล้วรอ output ทีเดียว"

  local machines=("win" "wsl" "tx" "deb")
  [[ "$target" != "all" ]] && machines=("$target")

  for m in "${machines[@]}"; do
    _xfm_valid "$m" || { _err "ไม่รู้จัก machine: $m"; continue; }
    echo ""
    echo -e "  $(_xfm_label "$m")  ${DIM}$(_xfm_conn_str "$m")${RESET}"
    _sep
    if [[ "${m,,}" == "local" || "${m,,}" == "." ]]; then
      df -h
    else
      _xfm_ssh "$m" "df -h" 2>/dev/null \
        | awk 'NR==1 { printf "  \033[1m%-20s  %-6s  %-6s  %-6s  %-5s  %s\033[0m\n",$1,$2,$3,$4,$5,$6; next }
               NR >1 {
                 used=$5+0
                 color="\033[0;32m"
                 if (used>=90) color="\033[1;31m"
                 else if (used>=70) color="\033[1;33m"
                 printf "  %-20s  %-6s  %-6s  %-6s  %s%-5s\033[0m  %s\n",$1,$2,$3,$4,color,$5,$6
               }' \
        || echo -e "  ${LRED}offline หรือเชื่อมต่อไม่ได้${RESET}"
    fi
  done
  echo ""
}

# ─────────────────────────────────────────────────────────────────
# xfm DU — ขนาดโฟลเดอร์ย่อยบน remote
# ─────────────────────────────────────────────────────────────────
xfm_du() {
  local arg="${1:?Usage: xfm du <machine:path>}"
  local machine path
  machine=$(_xfm_mach "$arg"); path=$(_xfm_path "$arg")
  _xfm_valid "$machine" || { _err "ไม่รู้จัก machine: $machine"; return 1; }

  _learn_box "xfm du — ขนาดโฟลเดอร์ย่อยบน remote" \
    "ssh user@host 'du -sh \"$path\"/*/  | sort -rh | head -20'" \
    "du -sh         |summarize human-readable" \
    "sort -rh       |เรียงจากใหญ่สุด (human-numeric sort)" \
    "head -20       |แสดงแค่ top 20"

  echo ""
  echo -e "  $(_xfm_label "$machine")  ${LCYAN}📊  $path${RESET}"
  _sep

  if [[ "${machine,,}" == "local" || "${machine,,}" == "." ]]; then
    du -sh "$path"/*/ 2>/dev/null | sort -rh | head -20 \
      | awk '{printf "  \033[1;33m%-10s\033[0m  %s\n", $1, $2}'
  else
    _xfm_ssh "$machine" \
      "du -sh \"$path\"/*/ 2>/dev/null | sort -rh | head -20" \
      | awk '{printf "  \033[1;33m%-10s\033[0m  %s\n", $1, $2}' \
      || echo -e "  ${LRED}ไม่สามารถดึงข้อมูลได้${RESET}"
  fi
  echo ""
}

# ─────────────────────────────────────────────────────────────────
# xfm FIND — ค้นหาไฟล์บน remote
# ─────────────────────────────────────────────────────────────────
xfm_find() {
  local machine="${1:?Usage: xfm find <machine> <name> [path]}"
  local name="${2:?Usage: xfm find <machine> <name> [path]}"
  local path="${3:-~}"
  _xfm_valid "$machine" || { _err "ไม่รู้จัก machine: $machine"; return 1; }

  _learn_box "xfm find — ค้นหาไฟล์บน remote" \
    "ssh user@host 'find \"$path\" -iname \"*${name}*\" -not -path \"*/\.*\"'" \
    "find           |recursive file search" \
    "-iname         |case-insensitive wildcard match" \
    "-not -path     |ข้ามโฟลเดอร์ซ่อน (.git .cache etc.)" \
    "(ssh)          |รัน find บน remote แล้วส่ง result กลับมาแสดงที่ local"

  _info "ค้นหา '$name' บน $(_xfm_label "$machine") ใน $path ..."
  echo ""

  if [[ "${machine,,}" == "local" || "${machine,,}" == "." ]]; then
    find "$path" -iname "*${name}*" -not -path '*/\.*' 2>/dev/null
  else
    _xfm_ssh "$machine" \
      "find \"$path\" -iname \"*${name}*\" -not -path '*/\.*' 2>/dev/null" \
      | while IFS= read -r f; do
          echo -e "  ${WHITE}📄 $f${RESET}"
        done \
      || echo -e "  ${LRED}ค้นหาไม่ได้ หรือ offline${RESET}"
  fi
  echo ""
}

# ─────────────────────────────────────────────────────────────────
# xfm SYNC — rsync สองทิศทาง (any → any)
# ─────────────────────────────────────────────────────────────────
xfm_sync() {
  local src_arg="${1:?Usage: xfm sync <src> <dst>  ex: xfm sync tx:~/projects wsl:~/projects}"
  local dst_arg="${2:?Usage: xfm sync <src> <dst>}"

  local src_m dst_m src_p dst_p
  src_m=$(_xfm_mach "$src_arg"); src_p=$(_xfm_path "$src_arg")
  dst_m=$(_xfm_mach "$dst_arg"); dst_p=$(_xfm_path "$dst_arg")

  _learn_box "xfm sync — rsync ข้ามเครื่อง" \
    "rsync -avz --progress --delete -e 'ssh -p <port>' src dst" \
    "-a             |archive: recursive + permissions + timestamps" \
    "-v             |verbose แสดงทุกไฟล์" \
    "-z             |compress ระหว่าง transfer ลด bandwidth" \
    "--progress     |progress bar" \
    "--delete       |ลบไฟล์ปลายทางที่ไม่มีใน source (true sync)" \
    "(remote→remote)|route ผ่าน local relay เหมือน xfm cp"

  _warn "--delete จะลบไฟล์ที่ dst แต่ไม่มีใน src"
  _confirm "ยืนยัน sync: $src_arg → $dst_arg?" || { _info "ยกเลิก"; return 0; }

  # local → remote
  if [[ "${src_m,,}" == "local" || "${src_m,,}" == "." ]]; then
    _step "sync: local:$src_p  →  $dst_m:$dst_p"
    local host user port
    host=$(_xfm_host "$dst_m"); user=$(_xfm_user "$dst_m"); port=$(_xfm_port "$dst_m")
    local ssh_opt="-o ConnectTimeout=8"
    [[ -n "$port" ]] && ssh_opt="$ssh_opt -p $port"
    rsync -avz --progress --delete -e "ssh $ssh_opt" "$src_p" "$user@$host:$dst_p" \
      && _ok "sync สำเร็จ"
    return
  fi

  # remote → local
  if [[ "${dst_m,,}" == "local" || "${dst_m,,}" == "." ]]; then
    _step "sync: $src_m:$src_p  →  local:$dst_p"
    local host user port
    host=$(_xfm_host "$src_m"); user=$(_xfm_user "$src_m"); port=$(_xfm_port "$src_m")
    local ssh_opt="-o ConnectTimeout=8"
    [[ -n "$port" ]] && ssh_opt="$ssh_opt -p $port"
    rsync -avz --progress --delete -e "ssh $ssh_opt" "$user@$host:$src_p" "$dst_p" \
      && _ok "sync สำเร็จ"
    return
  fi

  # remote → remote (relay)
  _step "sync (relay): $src_m:$src_p  →  [local]  →  $dst_m:$dst_p"
  local relay_dir; relay_dir=$(mktemp -d /tmp/xfm_sync_XXXXXX)
  trap "rm -rf '$relay_dir'" RETURN

  _info "Step 1/2 — pull จาก $src_m ..."
  _xfm_pull "$src_m" "$src_p" "$relay_dir/" || { _err "pull ล้มเหลว"; return 1; }

  _info "Step 2/2 — push ไปยัง $dst_m ..."
  local host user port
  host=$(_xfm_host "$dst_m"); user=$(_xfm_user "$dst_m"); port=$(_xfm_port "$dst_m")
  local ssh_opt="-o ConnectTimeout=8"
  [[ -n "$port" ]] && ssh_opt="$ssh_opt -p $port"
  rsync -avz --progress --delete -e "ssh $ssh_opt" "$relay_dir/" "$user@$host:$dst_p" \
    && _ok "sync สำเร็จ"
  rm -rf "$relay_dir"
}

# ─────────────────────────────────────────────────────────────────
# xfm PUSH / PULL — shorthand สำหรับ local↔remote
# ─────────────────────────────────────────────────────────────────
xfm_push() {
  local local_src="${1:?Usage: xfm push <local_path> <machine:dst>}"
  local dst_arg="${2:?Usage: xfm push <local_path> <machine:dst>}"

  _learn_box "xfm push — local → remote shorthand" \
    "rsync -avz --progress -e 'ssh -p <port>' \"$local_src\" user@host:\"dst\"" \
    "(shorthand)    |เหมือน xfm cp local:$local_src $dst_arg แต่พิมพ์สั้นกว่า" \
    "(push = ส่งออก)|ส่งจากเครื่องนี้ไปยัง remote"

  xfm_cp "$local_src" "$dst_arg"
}

xfm_pull() {
  local src_arg="${1:?Usage: xfm pull <machine:src> [local_dst]}"
  local local_dst="${2:-.}"

  _learn_box "xfm pull — remote → local shorthand" \
    "rsync -avz --progress -e 'ssh -p <port>' user@host:\"src\" \"$local_dst\"" \
    "(shorthand)    |เหมือน xfm cp $src_arg local:$local_dst แต่พิมพ์สั้นกว่า" \
    "(pull = ดึงเข้า)|ดึงจาก remote มาไว้ที่เครื่องนี้"

  xfm_cp "$src_arg" "$local_dst"
}

# ─────────────────────────────────────────────────────────────────
# xfm DISPATCHER
# ─────────────────────────────────────────────────────────────────
xfm() {
  local cmd="${1:-help}"
  shift 2>/dev/null
  case "$cmd" in
    status)      xfm_status        ;;
    ls)          xfm_ls "$@"       ;;
    cp)          xfm_cp "$@"       ;;
    mv)          xfm_mv "$@"       ;;
    rm)          xfm_rm "$@"       ;;
    mkdir)       xfm_mkdir "$@"    ;;
    info)        xfm_info "$@"     ;;
    df)          xfm_df "$@"       ;;
    du)          xfm_du "$@"       ;;
    find)        xfm_find "$@"     ;;
    sync)        xfm_sync "$@"     ;;
    push)        xfm_push "$@"     ;;
    pull)        xfm_pull "$@"     ;;
    help|--help|-h|"") xfm_help   ;;
    *)
      _err "ไม่รู้จักคำสั่ง xfm: $cmd"
      echo -e "  ${DIM}พิมพ์ ${RESET}${CYAN}xfm help${RESET}${DIM} เพื่อดูรายการทั้งหมด${RESET}"
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────
# WELCOME MESSAGE (แสดงตอน source)
# ─────────────────────────────────────────────────────────────────
echo -e "  ${LCYAN}🌐  xfm Cross-Machine loaded!${RESET}  พิมพ์ ${BOLD}xfm help${RESET} หรือ ${BOLD}xfm status${RESET}"
echo -e ""

# ─────────────────────────────────────────────────────────────────
# AUTO-WELCOME when sourced
# ─────────────────────────────────────────────────────────────────



# Run the banner
