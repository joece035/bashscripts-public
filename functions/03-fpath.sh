#!/bin/bash
# ============================================================
#----------PHAT FOR FUNCTION----------#
  export FUNC_DIR="$SSOT/functions"
  export sdcard="/data/data/com.termux/files/home/storage/shared"
 #--------- FUNCTION FORM ------------#

#-------------------------------------#

#-------PHAT FOR DASHBOARD ENGINE-----#
ep() {
  printf '%s\n' "$ENGINES_DIR/${1:-""}"
 }
#--------------------------------------#

#-------PHAT For HOME -----------------#
hop() {
  printf '%s\n' "$home/${1:-""}"
}
#--------------------------------------#

#-------PHAT For HOME -----------------#
sd() {
  printf '%s\n' "$sdcard/${1:-""}"
}
#--------------------------------------#

#-------PHAT For FUNCTION/LEARN ------#
# fn <file>           → $FUNC_DIR/<file>  (functions/)
# fn j <file>         → $SSOT/joe.learn/<file>

#--------------------------------------#
cdc() {

  [[ -d "$1" ]] && cd "$1" && cn 10 b "$(pwd)" || cn 196 b " no such file or directory "
}
#--------------------------------------#
fn() {
  local j=$(echo "$SSOT/functions/00.1-function-tools.sh")
  local jb="$(dirname $j)/joe-block/entry.sh"
  case "$1" in
    j)
      if (( $# >= 2 )); then
        printf '%s\n' "$SSOT/joe.learn/$2"   # fn j <file> → $SSOT/joe.learn/<file>
      else
        printf '%s' "$j"
      fi
      ;;
    jb) source "$jb" ;;
    *)
      if (( $# == 0 )); then
        printf '%s' "$SSOT/functions"
      else
        printf '%s\n' "$SSOT/functions/$@"
      fi
    ;;
  esac
}
#----symbolic link----#
slink_() {
    # สลับไฟล์จริง(src)กับไฟล์ที่สร้างลิงก์ไปหา(tar) แล้วค่อยสร้างลิงก์ใหม่
    # กรณีไฟล์จริงอยู่บน termux ต้องการ link ไป sd card
    local src="${1:?SELECT SOURCE}" #-- file จริงๆ
    local tar="${2:?SELECT TARGET}" #-- link ที่จะทำ
    cp -r "${src}" "${tar}" &&   #-- คัดลอกเนื้อหาไปใส่ไฟล์ปลายทางก่อน
    mv "${src}" "${src}.bk" &&  #-- backup file จริง
    ln -s "${tar}" "${src}" &&     #-- สร้าง symbolic link
    echo "done symbolic link $tar --> $src"
    rm -rf "${src}.bk"            #-- ลบไฟล์สำรอง
    # -- ไฟล์จริงจะย้ายไปอยู่ใน sd card และสร้าง link มาแทนที่ตัวเอง
}

ssh -i ~/.ssh/id_ed25519_termux usercivenz@wsl

# ==============================================================================
# Universal Helper: ensure <command> [package]
# ------------------------------------------------------------------------------
# ทำให้ command/tool ที่ระบุ "พร้อมใช้งาน"
#
# Usage:
#   ensure git
#   ensure python python3
#   ensure curl
#   ensure powershell.exe
#
# Contract:
#   0 = command พร้อมใช้งาน
#   1 = ทำให้พร้อมใช้งานไม่ได้
#   2 = argument / environment ไม่ถูกต้อง
# ==============================================================================

ensure() {
    local cmd="${1:-}"
    local pkg="${2:-$cmd}"

    # --------------------------------------------------------------------------
    # 0. Validate
    # --------------------------------------------------------------------------
    [[ -z "$cmd" ]] && {
        cn 196 bi "❌ ensure: missing command name" >&2
        return 2
    }

    # --------------------------------------------------------------------------
    # 1. Already available
    # --------------------------------------------------------------------------
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi

    # --------------------------------------------------------------------------
    # 2. External / Windows command
    # --------------------------------------------------------------------------
    # Linux/Termux ไม่ควรพยายามติดตั้ง .exe ผ่าน pkg/apt
    if [[ "$cmd" == *.exe ]]; then
        cn 220 bi "⚠️ External command '$cmd' not found" >&2
        return 1
    fi

    cn 220 bi "⚠️ '$cmd' not found → installing '$pkg'..." >&2

    # --------------------------------------------------------------------------
    # 3. Termux
    # --------------------------------------------------------------------------
    if command -v pkg >/dev/null 2>&1; then

        if ! pkg install -y "$pkg"; then
            cn 196 bi "❌ Failed to install '$pkg' via pkg" >&2
            return 1
        fi

    # --------------------------------------------------------------------------
    # 4. Debian / Ubuntu / WSL
    # --------------------------------------------------------------------------
    elif command -v apt-get >/dev/null 2>&1; then

        local apt_cmd=(apt-get)

        if (( EUID != 0 )); then
            if ! command -v sudo >/dev/null 2>&1; then
                cn 196 bi "❌ sudo is required but not installed" >&2
                return 1
            fi

            apt_cmd=(sudo apt-get)
        fi

        # update only once per shell session
        if [[ -z "${JOE_APT_UPDATED:-}" ]]; then
            if ! "${apt_cmd[@]}" update -qq; then
                cn 196 bi "❌ apt update failed" >&2
                return 1
            fi

            export JOE_APT_UPDATED=1
        fi

        if ! "${apt_cmd[@]}" install -y "$pkg"; then
            cn 196 bi "❌ Failed to install '$pkg' via apt" >&2
            return 1
        fi

    # --------------------------------------------------------------------------
    # 5. Unsupported environment
    # --------------------------------------------------------------------------
    else
        cn 196 bi "❌ No supported package manager found for '$cmd'" >&2
        return 1
    fi

    # --------------------------------------------------------------------------
    # 6. Verify
    # --------------------------------------------------------------------------
    if command -v "$cmd" >/dev/null 2>&1; then
        cn 10 bi "✅ '$cmd' is ready" >&2
        return 0
    fi

    cn 196 bi "❌ '$pkg' installed, but '$cmd' is still unavailable" >&2
    return 1
}
