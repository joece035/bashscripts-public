# ============================================================
# 3-Worlds — SSH + File Transfer (Single file, any terminal)
# ============================================================

# Env from .bashjoe

# --- Detect current world ---
_detect_world() {
  case "$(uname -o 2>/dev/null || uname)" in
    Android*)       echo "termux" ;;
    Linux*)         [[ -d /data/data/com.termux ]] && echo "termux" || echo "wsl" ;;
    CYGWIN*|MINGW*) echo "windows" ;;
    *)              echo "unknown" ;;
  esac
}
export _MY_WORLD="$(_detect_world)"

# --- SSH Shortcuts ---
unalias tac tm tw wsl cpw2t cpt2w push 2>/dev/null

tdb()  { ssh -p "${DEBAIN_PORT}" "${DEBAIN_USER}@${DEBAIN_IP}" "$@"; }
tac()  { ssh -p 8158 "${ACODE_USER}@${ACODE_IP}" "$@"; }
tm()  { ssh -p 8022 "${TERMUX_USER}@${TERMUX_IP}" "$@"; }
tw()  { ssh "${WINDOWS_USER}@${WINDOWS_IP}" "$@"; }
wsl() { ssh -i ~/.ssh/id_ed25519_wsl -p 22 "${WSL_USER}@${WSL_IP}" "$@"; }
Tw() { ssh -t "${WINDOWS_USER}@${WINDOWS_IP}" "'C:\Program Files\Git\bin\bash.exe' --login $@"; }
# --- rsync helpers ---
_rsync_tm()  { rsync -az --update --info=progress2 -e "ssh -p 8022" "$@" "${TERMUX_USER}@${TERMUX_IP}:"; }
_rsync_tm_get() { rsync -az --update --info=progress2 -e "ssh -p 8022" "${TERMUX_USER}@${TERMUX_IP}:${1}" "$2"; }

# ============================================================
# FILE TRANSFER & COMMANDS
# ============================================================

unalias managetm 2>/dev/null

_T_CACHE_DIR="/tmp/.termux_completion_cache"
_T_CACHE_TTL=30

_t_usage() {
  echo -e "\033[1;34mUsage:\033[0m $1 <source> <destination>"
}

_t_remote_paths() {
  local prefix="$1"
  local cache_key
  cache_key=$(echo "$prefix" | sed 's|/[^/]*$||; s|[^a-zA-Z0-9]|_|g')
  [[ -z "$cache_key" ]] && cache_key="root"
  local cache_file="$_T_CACHE_DIR/${cache_key}.cache"
  mkdir -p "$_T_CACHE_DIR"

  if [[ -f "$cache_file" ]]; then
    local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    [[ $age -lt $_T_CACHE_TTL ]] && grep "^$prefix" "$cache_file" 2>/dev/null && return
  fi

  local di
  dir=$(dirname "$prefix")
  [[ "$dir" == "." ]] && dir="~"

  tm "ls -1dp ${prefix}* 2>/dev/null || ls -1dp ${dir}/ 2>/dev/null" 2>/dev/null | tee "$cache_file"
}

tclcache() { rm -f "$_T_CACHE_DIR"/*; echo "🗑️  Cache cleared"; }

# Tab completion
_comp_cpw2t() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 1 ]]; then
    mapfile -t COMPREPLY < <(compgen -f -- "$cur")
    [[ ${#COMPREPLY[@]} -eq 1 && -d "${COMPREPLY[0]}" ]] && COMPREPLY[0]+="/"
  elif [[ $COMP_CWORD -eq 2 ]]; then
    mapfile -t COMPREPLY < <(_t_remote_paths "$cur")
  fi
}

_comp_cpt2w() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 1 ]]; then
    mapfile -t COMPREPLY < <(_t_remote_paths "$cur")
  elif [[ $COMP_CWORD -eq 2 ]]; then
    mapfile -t COMPREPLY < <(compgen -f -- "$cur")
    [[ ${#COMPREPLY[@]} -eq 1 && -d "${COMPREPLY[0]}" ]] && COMPREPLY[0]+="/"
  fi
}

complete -o nospace -F _comp_cpw2t cpw2t
complete -o nospace -F _comp_cpt2w cpt2w

# Public commands
managetm() {
  echo -e "\033[1;35m--- 3-Worlds Commands ---\033[0m"
  echo -e "\033[1;33mSSH:\033[0m   tm | tw | wsl"
  echo -e "\033[1;32mcpw2t\033[0m : Copy WSL → Termux \033[0;90m(Tab Complete)\033[0m"
  echo -e "\033[1;32mcpt2w\033[0m : Copy Termux → WSL \033[0;90m(Tab Complete)\033[0m"
  echo -e "\033[1;32mmvw2t\033[0m : Move WSL → Termux"
  echo -e "\033[1;32mmvt2w\033[0m : Move Termux → WSL"
  echo -e "\033[1;32mlst\033[0m   : List Termux files"
  echo -e "\033[1;32mtun\033[0m  : Run command on Termux"
  echo -e "\033[1;32mtclcache\033[0m : Clear cache"
}

cpw2t() {
  [[ $# -ne 2 ]] && _t_usage "cpw2t" "cpw2t ~/file.txt /sdcard/Download/" && return 1
  local dst="$2"; [[ "$dst" == "~" ]] && dst="."
  echo "📤 WSL → Termux: $1 → $dst"
  rsync -az --delete --info=progress2 -e "ssh -p 8022" "$1" "${TERMUX_USER}@${TERMUX_IP}:$dst"
}

cpt2w() {
  [[ $# -ne 2 ]] && _t_usage "cpt2w" "cpt2w /sdcard/Download/file.txt ~/Downloads/" && return 1
  local src="$1"; [[ "$src" == "~" ]] && src="."
  echo "📥 Termux → WSL: $src → $2"
  rsync -az --update --info=progress2 -e "ssh -p 8022" "${TERMUX_USER}@${TERMUX_IP}:$src" "$2"
}

mvw2t() {
  [[ $# -ne 2 ]] && _t_usage "mvw2t" "mvw2t ~/file.txt /sdcard/Download/" && return 1
  cpw2t "$1" "$2" && { echo "🗑️  Removing: $1"; rm -f "$1"; }
}

mvt2w() {
  [[ $# -ne 2 ]] && _t_usage "mvt2w" "mvt2w /sdcard/file.txt ~/Downloads/" && return 1
  cpt2w "$1" "$2" && { echo "🗑️  Removing remote: $1"; tm "rm -f '$1'"; }
}

lst() { tm "ls -lah '${1:-~}'"; }
ssht(){ tm; }
tun(){ [[ $# -eq 0 ]] && echo "Usage: tun <command>" && return 1; tm "$@"; }

alias w2t="cpw2t"
alias t2w="cpt2w"

# Info
whichworld() {
  echo -e "🌏 Current world: \033[1;33m$_MY_WORLD\033[0m"
  echo -e "  \033[1;36mWSL:\033[0m      ${WSL_USER}@${WSL_IP}"
  echo -e "  \033[1;36mTermux:\033[0m   ${TERMUX_USER}@${TERMUX_IP}"
  echo -e "  \033[1;36mWindows:\033[0m   ${WINDOWS_IP}"
}

# --- UPDATE (pull/merge from remote) ---
# ดึงไฟล์จาก remote มา overwriting ที่ local เฉพาะไฟล์ที่ remote ใหม่กว่า
update() {
  local src="$1"
  local dst="${2:-.}"
  [[ -z "$src" ]] && echo "Usage: update <remote_file> [local_dest]" && return 1
  
  echo "🔄 Updating from Termux: $src → $dst"
  rsync -az --update --info=progress2 -e "ssh -p 8022" "${TERMUX_USER}@${TERMUX_IP}:$src" "$dst"
}

# Push ไฟล์ไป remote แต่ไม่ทับไฟล์ที่ remote ใหม่กว่า  
push() {
  local src="$1"
  local dst="${2:-.}"
  [[ -z "$src" ]] && echo "Usage: push <local_file> [remote_dest]" && return 1
  
  echo "📤 Pushing to Termux: $src → $dst"
  rsync -az --update --info=progress2 -e "ssh -p 8022" "$src" "${TERMUX_USER}@${TERMUX_IP}:$dst"
}
