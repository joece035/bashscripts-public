# /bin/bash

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

    echo "✨ All done "
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
    # 1. เช็คว่าใส่ Port มาหรือไม่
    local port="${1:-}"
    if [ -z "$port" ]; then
        cn y bi "Usage: fpid <port>" ; return 1
    fi

    local pid=""
    local os_type="$(uname -s 2>/dev/null)"
    local use_sudo=""

    # --- 2. ค้นหา PID ตามสภาพแวดล้อม ---
    if [[ "$os_type" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
        # ฝั่ง Windows / Git Bash
        pid=$(netstat.exe -ano | grep LISTENING | grep ":$port " | awk '{print $5}' | sort -u | xargs)
    else
        # ฝั่ง Linux / WSL / Termux
        if [ -z "$TERMUX_VERSION" ] && [ "$(id -u)" -ne 0 ] && command -v sudo &>/dev/null; then
            use_sudo="sudo"
        fi

        if command -v lsof &>/dev/null; then
            pid=$($use_sudo lsof -ti:"$port" 2>/dev/null | sort -u | xargs)
        elif command -v ss &>/dev/null; then
            pid=$($use_sudo ss -tulpn "sport = :$port" 2>/dev/null | grep -oP 'pid=\K\d+' | sort -u | xargs)
        elif command -v netstat &>/dev/null; then
            pid=$($use_sudo netstat -tulpn 2>/dev/null | grep ":$port " | grep -oP '\d+(?=/) | sort -u | xargs')
        fi
    fi

    # --- 3. เช็คว่าเจอ PID หรือไม่ ---
    if [ -z "$pid" ]; then
        cn r bi "No process is running on port $port" ; return 1
    fi

    # --- 4. ถามยืนยันเพื่อ Kill Process ---
    cn 87 b "Found process running on port $port: (PID: $pid)"
    read -p "Do you want to kill process $pid? (y/n): " answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if [[ "$os_type" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
            # Windows: ดึงชื่อไฟล์ .exe (เช่น syncthing.exe) จาก PID
            local exe_name
            exe_name=$(tasklist.exe //FI "PID eq $pid" //FO CSV 2>/dev/null | awk -F'","' 'NR==2{print $1}' | tr -d '"')

            if [ -n "$exe_name" ]; then
                # สั่ง //IM เพื่อ kill ทุก Process ที่ชื่อตรงกัน (ตัวแม่+ตัวลูก) และใส่ //T กวาดทั้ง Tree
                taskkill.exe //F //IM "$exe_name" //T 2>/dev/null && cn 10 b "Killed all instances of '$exe_name'."
            else
                # Fallback สั่ง Tree kill ผ่าน PID
                taskkill.exe //F //T //PID $pid 2>/dev/null && cn 10 b "Process $pid killed."
            fi
        else
            # Linux / Termux / WSL: พยายามดึงชื่อเพื่อ pkill กวาดล้างทั้งตระกูล
            local first_pid
            first_pid=$(echo "$pid" | awk '{print $1}')
            
            local proc_name=""
            proc_name=$(ps -p "$first_pid" -o comm= 2>/dev/null | xargs)
            [ -z "$proc_name" ] && proc_name=$(cat "/proc/$first_pid/comm" 2>/dev/null)

            if [ -n "$proc_name" ] && command -v pkill &>/dev/null; then
                $use_sudo pkill -9 -f "$proc_name" 2>/dev/null
                cn 10 b "Killed all processes associated with '$proc_name'."
            else
                $use_sudo kill -9 $pid 2>/dev/null
                cn 10 b "Process $pid killed."
            fi
        fi
    else
        cn y b "Process $pid not killed."
    fi
}

# --video pattern 
f_video(){
    local target="${1:-$bk_boom}"
    local files=() v
    mapfile -t files < <(find "$target" -type f \( \
        -iname "*.mp4" -o \
        -iname "*.3gp" -o \
        -iname "*.flv" -o \
        -iname "*.avi" -o \
        -iname "*.mov" -o \
        -iname "*.mkv" -o \
        -iname "*.wmv" -o \
        -iname "*.FLV" -o \
        -iname "*.AVI" -o \
        -iname "*.MOV" -o \
        -iname "*.MKV" -o \
        -iname "*.WMV" -o \
        -iname "*_tmp" -o \
        -iname "*_TMP" -o \
        -iname "*_Tmp" -o \
        -iname "*_*" \
    \))
    if [[ -z "${files[@]}" ]]; then
        cn r bi "No files found"
        return 1
    fi
    for v in "${files[@]}"; do
        rc b "${v}"
    done
    cn gr d "found  $(cn 198 b "${#files[@]}")"
    
}


fnex(){
    local target pattern files count move_dir copy_dir
    target="${1:-$PWD}"
    pattern="${2:-*.sh}"
    count="$(find "$target" -type f -iname "${pattern}" 2>/dev/null | wc -l)"

    

    #เช็คว่ามีไฟล์
    files="$(find "$target" -type f -iname "${pattern}" 2>/dev/null | sort -u)"
    if [[ -z "$files" ]]; then
        cn r bi "No files found matching pattern "${pattern}" in directory "$target""; return 1
    fi
    
    #แสดง
    cn 45 b "$files"
    cn 10 b "$count files found "
    read -p "what do you want to do with these files? (rm/mv/cp/exit) : " answer

    if [[ "$answer" == "rm" ]]; then
        cn 45 b "Are you sure you want to delete these files? (y/n): "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            local rm_files=($files)
            for file in "${rm_files[@]}"; do
                [[ -f "$file" ]] && cn y bi "$file" && rm -f "$file" || cn r bi "$file not found"
            done
            cn lg b "Files deleted successfully"
        else
            cn y b "Files not deleted."
        fi
    elif [[ "$answer" == "mv" ]]; then
        cn 45 b "Enter the directory to move the files to: "
        read -r move_dir
        if [[ ! -d "$move_dir" ]]; then
            local rm_files=($files)
            mkdir -p "$move_dir" 
            for file in "${rm_files[@]}"; do
                if [[ -f "$file" ]]; then
                    mv "$file" "$move_dir" && cn y bi "Moved: $file"
                fi
            done
        else
            if [[ -f "$file" ]]; then
                mv "$file" "$move_dir" && cn y bi "Moved: $file"
            fi
        fi
    elif [[ "$answer" == "cp" ]]; then
        cn 45 b "Enter the directory to copy the files to: "
        read -r copy_dir
        if [[ -d "$copy_dir" ]] ; then
          find "$target" -type f  -iname "${pattern}" 2>/dev/null | xargs -p cp -v -t "$copy_dir"
        else
          cn r bi "Directory not found: $copy_dir"
          return 1
        fi
        find "$target" -type f  -iname "${pattern}" 2>/dev/null | xargs -p cp -v -t "$copy_dir"
    else
        cn y b "Invalid input."
    fi      
}

new() {
    local is_dir=0
    case ${1:--d} in
            -d) is_dir=1 && shift ;;
            -f|sh) is_dir=0 && shift ;;
            *)  cn y b "usage : -d or -f"; return 1 ;;
    esac
    local target="${2:-}"

    if [[ $is_dir -eq 1 ]]; then
        mkdir -p "$target" && cn y bi "✅ โฟลเดอร์ถูกสร้างเรียบร้อยที่: $target"
    else
        if [[ "$is_dir" -eq 0 && "$1" == "sh" ]]; then
           sh_ "$target"
        else
            mkdir -p "$(dirname "$target")" 
            touch "$target" && cn y bi "✅ ไฟล์ถูกสร้างเรียบร้อยที่: $target"
        fi
    fi
}


sh_(){
    local target="${1:-}"
    mkdir -p "$(dirname "$target")"  
    touch "$target" && perm "$target" && cn y bi "✅ ไฟล์ .sh ถูกสร้างเรียบร้อยที่: $target"
}

 