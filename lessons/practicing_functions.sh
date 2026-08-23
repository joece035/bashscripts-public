#!/bin/bash

replace_w() {
    local old_name=${1:-}
    local new_name=${2:-}
    local target=${3:-$PWD}

    if [[ -z "$old_name" || -z "$new_name" ]]; then
        echo "Usage: change_word <old_name> <new_name> [target_folder]"
        return 1
    fi

    echo "Replacing '$old_name' with '$new_name' in $target..."

    # ครอบเครื่องหมายคำพูดซ้อนสไตล์นี้ปลอดภัยที่สุดครับ
    find "$target" -type f -exec sed -i "s/""$old_name""/""$new_name""/g" {} +

    echo "✨ All done!"
}

rename_multi(){
    local target="${1:-$PWD}"
    # วนลูปอ่านทุกไฟล์
    for file in *; do
        # ตรวจสอบว่ามีไฟล์อยู่จริง (ป้องกันกรณีไม่มีไฟล์ .jpg)
        [ -e "$file" ] || continue
        # ดึงวันที่แก้ไขล่าสุดของไฟล์ในรูปแบบ YYYY-MM-DD_HHMMSS
        # Linux (Ubuntu/WSL):
        date_str=$(stat -c %y "$file" | awk '{print $1"_" $2}' | cut -d'.' -f1 | tr ':' '-')
        
        # แยกชื่อไฟล์เดิมและนามสกุล
        ext="${file##*.}"

        # กำหนดชื่อใหม่
        new_name="${date_str}.${ext}"

        # แสดงผลการทำงานก่อน (DRY RUN)
        echo "Renaming: '$file' -> '$new_name'"
        
        # หากต้องการให้เปลี่ยนชื่อจริง ให้เอา # ข้างหน้า mv ออก
        mv "$file" "$new_name"
    done
}

fpid() {
    local port="${1:-}"
    if [ -z "$port" ]; then
        cn y bi "Usage: fpid <port>" ; return 1
    fi

    local pid=""
    local os_type="$(uname -s 2>/dev/null)"

    # --- 1. กรณีรันบน Git Bash (Windows / MSYS / MINGW) ---
    if [[ "$os_type" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        # ใช้ netstat.exe ของ Windows สกัดเอา PID
        pid=$(netstat.exe -ano | grep LISTENING | grep ":$port " | awk '{print $5}' | sort -u | xargs)
        
        if [ -z "$pid" ]; then
            cn r bi "No process is running on port $port" ; return 1
        fi

        cn 87 b "Found process on Windows port $port (PID: $pid)"
        read -p "Do you want to kill process $pid? (y/n): " answer

        if [[ "$answer" =~ ^[Yy]$ ]]; then
            # ใช้ taskkill.exe ของ Windows สั่งลบโปรเซส
            taskkill.exe //F //PID $pid 2>/dev/null && cn 10 b "Process $pid killed." || cn y bi "Can't kill process $pid."
        fi
        return 0
    fi

    # --- 2. กรณีรันบน Linux / WSL / Termux (ใช้โค้ดเดิม) ---
    local use_sudo=""
    if [ -z "$TERMUX_VERSION" ] && [ "$(id -u)" -ne 0 ] && command -v sudo &>/dev/null; then
        use_sudo="sudo"
    fi

    if command -v lsof &>/dev/null; then
        pid=$($use_sudo lsof -ti:"$port" 2>/dev/null | sort -u | xargs)
    elif command -v ss &>/dev/null; then
        pid=$($use_sudo ss -tulpn "sport = :$port" 2>/dev/null | grep -oP 'pid=\K\d+' | sort -u | xargs)
    fi

    if [ -z "$pid" ]; then
        cn r bi "No process is running on port $port" ; return 1
    fi

    cn 87 b "Found process on port $port (PID: $pid)"
    read -p "Do you want to kill process $pid? (y/n): " answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        $use_sudo kill -9 $pid 2>/dev/null && cn 10 b "Process $pid killed." || cn y bi "Can't kill process $pid."
    fi
}


