#!/bin/bash
# ============================================================
# system.sh — System & Network Utilities
# ============================================================
fp() {
    local p="${1:-}"
    if [[ -z "$p" ]]; then echo "Usage: fp <port>"; return 1; fi
    local pid=$(ss -tlnp "sport = :$p" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1)
    if [[ -n "$pid" ]]; then cn 46 b "Port $p is LISTENING - PID: $pid"
    else cn 226 "" "Port $p is NOT in use"; fi
}
kp() {
    local port=$1
    if [ -z "$port" ]; then cn 196 b "❌ Usage: kpfp <port_number>"; return 1; fi
    local pid=$(lsof -t -i:$port)
    if [ -n "$pid" ]; then
        cn 226 "" "🔍 Found Process on Port $port and PID:$pid"
        kill -9 $pid; cn 196 b "✅ Process $pid has been killed."
    else cn 226 "" "🔍 No process found running on port $port"; fi
}
fpk() {
    local port=$1
    if [ -z "$port" ]; then cn 196 b "❌ Usage: fpk <port_number>"; return 1; fi
    local pid=$(lsof -t -i:$port)
    if [ -n "$pid" ]; then
        cn 51 b "🔍 Found Process on Port $port:"
        lsof -i:$port
        printf '%s' "$(c 226 b '⚠️ Do you want to kill PID '$pid'? (y/n): ')"
        read confirm
        if [[ "$confirm" == [yY] ]]; then kill -9 $pid; cn 46 b "✅ Process $pid has been killed."
        else cn 196 b "❌ Canceled."; fi
    else cn 226 "" "🔍 No process found running on port $port"; fi
}
gpc() {
    if [ -z "$1" ]; then
         ss -tulpn | grep LISTEN
    else
        ss -tulpn | grep LISTEN | grep ":$1 "
    fi
}
kk() {
    killall -9 termux-info 2>/dev/null; pkill -9 -u $(whoami)
}
kkk() {
    cn 196 b "☢️ DEPLOYING NUCLEAR KILL..."
    kill -9 $(pgrep -f "python|node|cmd") 2>/dev/null; echo "All killed."
    cn 46 b "✅ Cleanup Complete!"
}
kkkk() {
    cn 196 b "☠️ SYSTEM PURGE (Python/Node/CMD)"
    taskkill.exe /F /IM python.exe /T /FI "STATUS eq RUNNING"
    taskkill.exe /F /IM node.exe /T /FI "STATUS eq RUNNING"
    taskkill.exe /F /IM cmd.exe /T /FI "STATUS eq RUNNING"
    cn 46 b "✅ All targets neutralized."
}
_init_scrcpy_env() {
    if [[ "$JOE_ENV" == "GIT-BASH" ]]; then
        local win_scrcpy_dir="$dtpc/scrcpy-win64-v2.4"
        ADB_EXEC="$win_scrcpy_dir/adb.exe"
        SCRCPY_EXEC="$win_scrcpy_dir/scrcpy.exe"
    elif [[ "$JOE_ENV" == "WSL" ]]; then
        local wsl_scrcpy_dir="$hpc/Desktop/scrcpy-win64-v2.4"
        ADB_EXEC="$wsl_scrcpy_dir/adb.exe"
        SCRCPY_EXEC="$wsl_scrcpy_dir/scrcpy.exe"
    else
        ADB_EXEC="adb"
        SCRCPY_EXEC="scrcpy"
    fi
}
adb() {
    _init_scrcpy_env
    "$ADB_EXEC" "$@"
}
opmb() {
    _init_scrcpy_env
    local target_ip="${NODE_TERMUX_HOST:-termux}"

    if [[ -n "$1" ]]; then
        cn 51 b "📡 Connecting to Mobile ($target_ip:$1)..."
        "$ADB_EXEC" disconnect > /dev/null 2>&1
        "$ADB_EXEC" connect "$target_ip:$1" > /dev/null 2>&1
        "$SCRCPY_EXEC" -s "$target_ip:$1" &
    else
        local sys_adb
        if command -v adb.exe &>/dev/null; then sys_adb="adb.exe"
        elif command -v adb &>/dev/null; then sys_adb="adb"
        else sys_adb="$ADB_EXEC"; fi

        local tcp_devices
        tcp_devices=$("$sys_adb" devices 2>/dev/null | grep -w "device" | awk '{print $1}')

        local count
        count=$(echo "$tcp_devices" | grep -c .)

        if [[ "$count" -eq 1 ]]; then
            cn 51 b "📡 Warping to Mobile ($tcp_devices)..."
            "$SCRCPY_EXEC" -s "$tcp_devices" &
        elif [[ "$count" -gt 1 ]]; then
            local wireless
            wireless=$(echo "$tcp_devices" | grep -v ":5555$" | head -1)
            if [[ -n "$wireless" ]]; then
                cn 226 "" "⚠️ Multiple devices found, using wireless: $wireless"
                "$SCRCPY_EXEC" -s "$wireless" &
            else
                cn 196 b "❌ Multiple devices but no wireless debugging port found. Use: opmb <port>"
            fi
        else
            cn 196 b "❌ No ADB device connected. Run: adb connect $target_ip:<port>"
        fi
    fi
}
opmm() {
    _init_scrcpy_env
    cn 226 "" "⚠️ Warning: OTG mode REQUIRES a physical USB connection."
    "$SCRCPY_EXEC" --otg &
}
etext() {
    local OLD="$1"
    local NEW="$2"
    local NPATH="${3:-$PWD}"

    if [[ -z "$OLD" || -z "$NEW" ]]; then
        echo "❌ วิธีใช้: etext <ชื่อเดิม> <ชื่อใหม่> [โฟลเดอร์]"
        return 1
    fi

    echo "🔎 [1/3] SCAN: กำลังค้นหา '$OLD' ใน 📁 $NPATH ..."
    local TMPFILE=$(mktemp)
    find "$NPATH" -type f \( -name "*.md" -o -name "*.json" -o -name "*.txt" -o -name "*.env" -o -name "*.py" -o -name "*.sh" \) -not -path "*/.git/*" -not -path "*/node_modules/*" \
        -exec grep -lF "$OLD" {} + 2>/dev/null > "$TMPFILE"

    local FILE_COUNT=$(wc -l < "$TMPFILE" | tr -d ' ')

    if [[ "$FILE_COUNT" -eq 0 ]]; then
        rm -f "$TMPFILE"
        echo "⚠️ ไม่พบ '$OLD' ในไฟล์ใดๆ"
        return 0
    fi

    echo "✅ พบ $FILE_COUNT ไฟล์ที่มี '$OLD':"
    while IFS= read -r f; do echo "   • $f"; done < "$TMPFILE"
    echo

    echo "👁️  [2/3] PREVIEW: ตัวอย่างการเปลี่ยนแปลง:"
    echo "─────────────────────────────────────────"
    local SHOW=0
    while IFS= read -r file; do
        [[ $SHOW -ge 5 ]] && break
        grep -nF "$OLD" "$file" | head -2 | while IFS= read -r line; do
            local lineno="${line%%:*}"
            local content="${line#*:}"
            local preview="${content//$OLD/→$NEW←}"
            echo "📄 $file:$lineno"
            echo "   - $content"
            echo "   + $preview"
            echo
        done
        SHOW=$((SHOW + 1))
    done < "$TMPFILE"
    echo "─────────────────────────────────────────"

    read -p "✅ ยืนยันการเปลี่ยนทั้งหมด? [Y/n]: " -n 1 -r CONFIRM
    echo

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && [[ -n "$CONFIRM" ]]; then
        echo "❌ ยกเลิกการดำเนินการ"
        rm -f "$TMPFILE"
        return 0
    fi

    echo "⚙️  [EXECUTE] กำลังประมวลผล..."
    local BACKUP_DIR=".etext_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    while IFS= read -r file; do
        cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
        OLD_ESCAPED=$(printf '%s\n' "$OLD" | sed 's/[|&]/\\&/g')
        NEW_ESCAPED=$(printf '%s\n' "$NEW" | sed 's/[|&]/\\&/g')
        sed -i "s|$OLD_ESCAPED|$NEW_ESCAPED|g" "$file"
    done < "$TMPFILE"

    rm -f "$TMPFILE"
    echo "✨ เสร็จสิ้น! เปลี่ยน '$OLD' → '$NEW' ใน $FILE_COUNT ไฟล์"
    echo " ไฟล์สำรอง: 📁 $BACKUP_DIR"
    echo "🗑️  ลบสำรองเมื่อพอใจ: rm -rf $BACKUP_DIR"
}
ftext() {
    if [ -z "$1" ]; then
        echo "กรุณาระบุข้อความที่ต้องการค้นหา"
        return 1
    fi
    grep -rn "$1" "${2:-$PWD}"
}
rbfe() {
    cd "$DASHBOARD_DIR/frontend"
    pnpm run build
    pwd
    cn 46 b "✅ DONE running frontend .. 🚀"
}
pushbsc() {
    cpw2t ~/bashscripts/. $htm/bashscripts && cn 46 b "✅ bashscripts pushed to TERMUX HOME!"
}
load_env_chain() {
    local project_env=""
    set -a
    [[ -f "$HOME/.env" ]] && source "$HOME/.env"
    [[ -f "$OP_ENV" ]] && source "$OP_ENV"
    if [[ -f "$PWD/.env" ]]; then
        project_env="$PWD/.env"
        source "$project_env"
    fi
    set +a
    export CURRENT_ENV_FILE="${project_env:-$OP_ENV}"
    cn 46 b "✅ Environment Loaded"
    echo "   🌍 Global  : $HOME/.env"
    echo "   🐾 Profile : ${OP_ENV:-None}"
    echo "   📦 Project : ${project_env:-None}"
    echo "   🎯 Active  : ${CURRENT_ENV_FILE}"
}
alias envp="load_env_chain"
terminal_theme() {
        cd ~/terminal && pnpm dev
}
alias tmnal='terminal_theme'





set_(){

printf -v "$1" '%s' "$2"

}
draw_() {
    local char="$1"
    local count="$2"
    # ใช้ Bash string substitution แทน sed (ปลอดภัยกว่ากับ escape sequences)
    printf -v space_ '%*s' "$count" ''
    printf '%s' "${space_// /$char}"
}




slink(){
   # --at gitbash
   # 1. กำหนดค่าตัวแปร และครอบ Double Quotes เพื่อป้องกันปัญหาเรื่อง Path ที่มี Space (ช่องว่าง) source = symlink , target=fileจริง
   local src="${1:-${PWD}}"
   local tar="${2:?SELECT TARGET}"
   
   # 2. คัดลอกและแบ็คอัพ
   cp -r "${src}" "$(dirname "${tar}")" && mv "${src}" "${src}bk"
   
   # 3. สร้าง Symlink และแสดงผล (แก้เรื่องการซ้อน Quotes และคำผิดนิดหน่อย)
   ln -s "${tar}" "${src}" && echo "done symbolic link ${src} --> ${tar}"
   # หมายเหตุ: ถ้าแกมีฟังก์ชัน c lg bi อยู่แล้ว ให้ใช้:
   # ln -s "${tar}" "${src}" && c lg bi "done symbolic link ${src} --> ${tar}"
}