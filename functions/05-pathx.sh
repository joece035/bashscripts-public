#!/bin/bash





pathx() {
    local input_path
    local target_format="wsl" # Default target format

    # Handle smart flags
    if [[ "$1" == "win" ]]; then
        target_format="win"
        shift
    elif [[ "$1" == "wsl" ]]; then
        target_format="wsl"
        shift
    elif [[ "$1" == "git" ]]; then
        target_format="git"
        shift
    fi

    # Handle argument or clipboard input
    if [[ -n "$1" ]]; then
        input_path="$1"
    else
        # Read from Windows clipboard
        input_path=$(powershell.exe -Command "Get-Clipboard" | tr -d '\r')
    fi

    if [[ -z "$input_path" ]]; then
        echo "Error: No path provided and clipboard is empty."
        return 1
    fi

    local detected_source_format=""
    local common_path=""

    # Auto-detect source format and convert to a common internal format (e.g., C:/Users/User)
    if [[ "$input_path" =~ ^[A-Za-z]:\\ ]]; then
        # Windows path (e.g., C:\Users\User)
        detected_source_format="win"
        common_path=$(echo "$input_path" | sed 's/\\/\//g') # Convert backslashes to forward slashes
    elif [[ "$input_path" =~ ^/mnt/[A-Za-z]/ ]]; then
        # WSL path (e.g., /mnt/c/Users/User)
        detected_source_format="wsl"
        common_path=$(echo "$input_path" | sed 's/^\/mnt\/\([A-Za-z]\)/\U\1:/') # /mnt/c/ -> C:
    elif [[ "$input_path" =~ ^/[A-Za-z]/ ]]; then
        # Git Bash path (e.g., /c/Users/User)
        detected_source_format="git"
        common_path=$(echo "$input_path" | sed 's/^\/\([A-Za-z]\)/\U\1:/') # /c/ -> C:
    else
        echo "Error: Could not detect source path format for: $input_path"
        return 1
    fi

    local output_path=""

    # Convert from common_path to target_format
    if [[ "$target_format" == "win" ]]; then
        output_path=$(echo "$common_path" | sed 's/^\([A-Za-z]\):/\1:/' | sed 's/\//\\/g') # C:/ -> C: and / -> \
    elif [[ "$target_format" == "wsl" ]]; then
        output_path=$(echo "$common_path" | sed 's/^\([A-Za-z]\):/\/mnt\/\L\1/') # C: -> /mnt/c
    elif [[ "$target_format" == "git" ]]; then
        output_path=$(echo "$common_path" | sed 's/^\([A-Za-z]\):/\/\L\1/') # C: -> /c
    fi

    # Output to stdout
    echo "$output_path"

    # Copy to clipboard
    powershell.exe -Command "Set-Clipboard -Value \"$output_path\""
}

# ---------- claude ----------#
# ─────────────────────────────────────────────
# p() — Universal Path Compatibility Layer
# Drop into ~/.bashrc / ~/.zshrc (WSL / Git Bash)
# ─────────────────────────────────────────────

# ── p() v3 — JOE_ENV-aware, handles Windows + WSL UNC paths ──
# ~/.bashrc (WSL + Git Bash)

WSL_DISTRO="Ubuntu"   # ← แก้ตรงนี้ถ้าเปลี่ยน distro

p() {
  if ! command -v cb_read >/dev/null 2>&1; then
    _check -f "$SSOT/core/ssh_toolkit.sh" "source" 2>/dev/null && echo "done source toolkit"
  fi
  local raw converted drive rest distro

  # 1. Input: $1 หรือ clipboard
  raw="${1:-$(cb_read)}"
  [[ -z "$raw" ]] && { echo "[p] No input." >&2; return 1; }

  # 2. Normalize whitespace + backslash → /
  raw="$(echo "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '\\' '/')"
  # หลัง normalize backslash → เพิ่มบรรทัดนี้
raw="${raw//\"/}"   # ลบ double quote ออกทั้งหมด
raw="${raw//\'/}"   # ลบ single quote ออกด้วยเ
  [[ "$raw" =~ ^/wsl\.localhost/ ]] && raw="/$raw"  # เติม / นำหน้าถ้าขาด
  # 3. Detect + convert
  # ── Case A: WSL UNC path  //wsl.localhost/Ubuntu/home/... ──
  if [[ "$raw" =~ ^//wsl\.localhost/([^/]+)(/.*)$ ]]; then
    # Portable regex match extraction (bash: BASH_REMATCH, zsh: match[])
    if [[ -n "${BASH_VERSION:-}" ]]; then
      distro="${BASH_REMATCH[1]}"
      rest="${BASH_REMATCH[2]}"
    else
      distro="${match[1]}"
      rest="${match[2]}"
    fi

    case "${JOE_ENV}" in
      WSL)      converted="$rest" ;;
      GIT-BASH) converted="//wsl.localhost/${distro}${rest}" ;;
      WIN)      converted="\\\\wsl.localhost\\${distro}$(echo "$rest" | tr '/' '\\')" ;;
      *)        converted="$rest" ;;
    esac

  # ── Case B: Windows drive path  C:/Users/... ──
  elif [[ "$raw" =~ ^([A-Za-z]):(/.*)$ ]]; then
    if [[ -n "${BASH_VERSION:-}" ]]; then
      drive="${BASH_REMATCH[1],,}"
      rest="${BASH_REMATCH[2]}"
    else
      drive="${(L)match[1]}"
      rest="${match[2]}"
    fi

    case "${JOE_ENV}" in
      WSL)      converted="/mnt/${drive}${rest}" ;;
      GIT-BASH) converted="/${drive}${rest}" ;;
      WIN)      converted="${drive^^}:$(echo "$rest" | tr '/' '\\')" ;;
      *)        converted="/mnt/${drive}${rest}" ;;
    esac

  else
    echo "[p] Unrecognized path format: $raw" >&2
    return 1
  fi

  # 4. Output + clipboard
  echo "$converted"
  cb_copy "$converted"
}



imma_jump_to_the_fucking_god_damn_windows_path_from_wsl_by_typing_only_fuckin_j() {
   cdc "$(p)"
}
alias j='imma_jump_to_the_fucking_god_damn_windows_path_from_wsl_by_typing_only_fuckin_j' 




