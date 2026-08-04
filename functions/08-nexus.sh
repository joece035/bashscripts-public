#!/bin/bash
#  --------------------  SYNCTHING AUTO START  --------------------  #
alias nx="bash $nexus_vault/scripts/nexus-panel.sh"

pull_termux_to_windows() {
    # 1. Platform Protection
    if [[ "$JOE_ENV" != "WSL" ]]; then
        cn r b "❌ Error: คำสั่งนี้ต้องรันบน WSL2 เพื่อเป็นสะพานเชื่อมเท่านั้นครับ!"
        return 1
    fi

    local tm_file="$1"    # ไฟล์/โฟลเดอร์ต้นทางฝั่ง Termux
    local dest_file="$2"  # ไฟล์/โฟลเดอร์ปลายทางฝั่ง Windows

    # ดัก Argument ว่าง
    if [[ -z "$tm_file" || -z "$dest_file" ]]; then
        cn r b "❌ Usage: cptw <file_in_termux> <target_in_windows>"
        return 1
    fi
    local dest_name="$dest_file"

    # 2. Setup Full Paths (No Hardcoded Paths)
    local target_path="$hpc/$dest_name"
    local dest_dir=$(dirname "$target_path")
    mkdir -p "$dest_dir"

    # 3. Dynamic SSH Config (ดึงค่าจาก 00-env.sh Node Registry ที่โหลดเข้า Env แล้ว)
    # ใช้ค่าเริ่มต้น (Fallback) เป็น MagicDNS hostname เผื่อตัวแปรว่าง
    local ssh_ip="${NODE_TERMUX_HOST:-termux}"
    local ssh_port="${NODE_TERMUX_PORT:-8022}"
    local ssh_user="${NODE_TERMUX_USER:-}" # ถ้ามี user ให้ใส่เพิ่มได้
    
    # จัดรูปฟอร์มของ SSH Host
    local ssh_host="$ssh_ip"
    if [[ -n "$ssh_user" ]]; then
        ssh_host="${ssh_user}@${ssh_ip}"
    fi

    cn y d "📡 [3WORLDS] Connecting to Termux (${ssh_host}:${ssh_port}) to pull: $tm_file ..."
    
    # 4. Direct Pipeline via SSH/SCP (ยิงตรงไร้จุดพัก และ No-Hardcode)
    # ใช้ $htm ซึ่งระบุพิกัดหน้าบ้านของ Termux ข้ามโลกมาลง $target_path บน Windows ตรงๆ
    scp -r -P "$ssh_port" "${ssh_host}:$htm/$tm_file" "$target_path"

    # 5. Post-verification
    if [[ -e "$target_path" ]]; then
        cn lg b "✅ [WSL-BRIDGE] Pull Success: Termux:$tm_file -> Windows:$dest_name"
    else
        cn r b "❌ Error: ไม่สามารถดึงไฟล์จาก Termux ได้ (เช็คคอนฟิกใน 3worlds.sh หรือยัง?)"
        return 1
    fi
}
alias cptw='pull_termux_to_windows'

 

  

 auto_write_file() {
    local HEAD_NAME=${1:-"FUNCTION"}
    local FILE_PATH=${2:-"$(fn 08-nexus.sh)"}
    local width=50
    local TEXT=${3:-"TYPE SOMETHING"}

    # ถ้าไม่มี $3 ให้อ่านจาก stdin (รองรับ heredoc สำหรับข้อความหลายบรรทัด/มีตัวแปร)
    if [[ -z "${3:-}" ]] && [[ ! -t 0 ]]; then
        TEXT=$(cat)
    fi

    # คลี่ Path ในกรณีที่มีตัวแปรเช่น $HOME หรือ ~
    FILE_PATH=$(eval echo "${FILE_PATH:-$PWD/output.txt}")

    local title=" $HEAD_NAME " # ใส่ช่องไฟซ้าย-ขวาให้ข้อความหัวเรื่อง
    local char_count
    char_count=$(printf "%s" "$title" | wc -m)
    
    # ดักกรณีถ้าข้อความยาวเกินความกว้างกล่องที่ตั้งไว้ ($width) ให้ขยายกล่องอัตโนมัติเพื่อไม่ให้เส้นพัง
    if [ "$char_count" -gt "$width" ]; then
        width=$((char_count + 4)) # ขยายขนาดกล่องให้กว้างกว่าข้อความ
    fi

    # คำนวณขอบซ้าย-ขวา เพื่อปูทางให้ความกว้างรวมออกมาคงที่เท่ากับ $width เป๊ะๆ
    local pad=$(( (width - char_count) / 2 ))
    local rem=$(( width - char_count - pad ))

    local left_space
    left_space=$(printf "%${pad}s" "")
    local right_space
    right_space=$(printf "%${rem}s" "")
    
    # ความยาวของเส้นใต้ จะเท่ากับจำนวนตัวหนาทั้งหมดรวมกัน (pad + ข้อความ + rem) 
    # ซึ่งก็คือค่า $width พอดีเป๊ะ!
    local main_line
    main_line=$(printf "%${width}s" | sed 's/ /▬/g')

    # ประกอบร่าง Header & Footer Block 
    # (ครอบด้วย # และปิดด้วย # ให้เหมือนกันทั้งบนและล่าง)
    local head_line_top="# ${main_line} #"
    local head_line_mid="# ${left_space}${title}${right_space} #"
    local head_line_bot="# ${main_line} #"
    
    {
        echo " "
        echo "$head_line_top"
        echo "$head_line_mid"
        echo "$head_line_bot"
        printf '%s\n' "$TEXT"
        echo " "
    } >> "${FILE_PATH}"
    
   

  c lg b "✅ Text Box Written "${TEXT}"  to: "${FILE_PATH}"" 
}

alias atype='auto_write_file'








