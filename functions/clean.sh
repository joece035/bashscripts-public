#!/bin/bash
#-- file นี้ เป็น scripts สำหรับงาน clean
array_excample(){
    local s="${1:-$video_p}"
    local d="${2:-$bk_path}"
    local files=("${s}"/*.mp4)

   rename_sp "$s"

   for f in ${files[@]} ; do
        cn 10 b "${f}"
   done

   mapfile -t files2 < <(find $s -name '*.mp4')
        for f2 in ${files2[@]} ; do
        cn 198 b "${f2}"
   done
}

rename_sp() {
    local target_dir="${1:-.}"
    local count=$(find "$target_dir" -type f \( \
        -iname "* *.mp4" -o \
        -iname "* *.3gp" -o \
        -iname "* *.flv" -o \
        -iname "* *.avi" -o \
        -iname "* *.mov" -o \
        -iname "* *.mkv" -o \
        -iname "* *.wmv" -o \
        -iname "* *.FLV" -o \
        -iname "* *.AVI" -o \
        -iname "* *.MOV" -o \
        -iname "* *.MKV" -o \
        -iname "* *.WMV" -o \
        -iname "* *_tmp" -o \
        -iname "* *_TMP" -o \
        -iname "* *_Tmp" -o \
        -iname "*_*" \
    \) | wc -l)

    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' does not exist."
        return 1
    fi

    cn 20 b "Found $count files to rename in: $target_dir"
    read -p "Do you want to rename them? (y/n)" -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        cn 10 b "Operation cancelled."
        return 0
    fi

    find "$target_dir" -type f \( \
        -iname "* *.mp4" -o \
        -iname "* *.3gp" -o \
        -iname "* *.flv" -o \
        -iname "* *.avi" -o \
        -iname "* *.mov" -o \
        -iname "* *.mkv" -o \
        -iname "* *.wmv" -o \
        -iname "* *.FLV" -o \
        -iname "* *.AVI" -o \
        -iname "* *.MOV" -o \
        -iname "* *.MKV" -o \
        -iname "* *.WMV" -o \
        -iname "* *_tmp" -o \
        -iname "* *_TMP" -o \
        -iname "* *_Tmp" -o \
        -iname "*_*.mp4" -o \
        -iname "*_*.flv" -o \
        -iname "*_*.avi" -o \
        -iname "*_*.mov" -o \
        -iname "*_*.mkv" -o \
        -iname "*_*.wmv" -o \
        -iname "*_*.FLV" -o \
        -iname "*_*.AVI" -o \
        -iname "*_*.MOV" -o \
        -iname "*_*.MKV" -o \
        -iname "*_*.WMV" -o \
        -iname "*_tmp" -o \
        -iname "*_TMP" -o \
        -iname "*_Tmp" -o \
        -iname "*_ * " \
    \) -print0 | while IFS= read -r -d '' file; do
        local dir_path="$(dirname "$file")"
        local filename="$(basename "$file")"
        local new_filename="${filename// /}"
        local new_file_path="$dir_path/$new_filename"

        if [ -e "$new_file_path" ]; then
            cn 198 b "Skip: '$new_file_path' already exists."
            continue
        fi

        mv "$file" "$new_file_path"
        cn 10 b "Renamed: '$file' -> '$new_file_path'"
    done

    cn 10 b "Done!"
}
mv_(){
    local s="/f/Users/JoEz/Videos/clips"
    local d="/f/Users/JoEz/Videos/HunterxHunter"
    local count=$(find "$s" -type f -name 'HUNTER*' -print0 | wc -l)
    local file2=( "$s"/HUNTER* )
    mkdir -p $d
        for f in ${files2[@]} ; do
        local file_name
        file_name="$(basename "$f")"

        mv "$f" "$d/$file_name" \
            && cn 10 b "done moved $file_name" \
            || cn r b "cant moved $file_name"
        cn 198 b "$count files"
   done 
  c gr "" "ย้ายไฟล์แล้วทั้งหมด" ; c 10 b "$count" ; cn gr "" "files"
}
move_() {
    local src="${1:-$boom}"
    local dest="${2:-$bk_boom}"
    local count=$(find "$src" -type f \( \
        -iname "* *.mp4" -o \
        -iname "* *.3gp" -o \
        -iname "* *.flv" -o \
        -iname "* *.avi" -o \
        -iname "* *.mov" -o \
        -iname "* *.mkv" -o \
        -iname "* *.wmv" -o \
        -iname "* *.FLV" -o \
        -iname "* *.AVI" -o \
        -iname "* *.MOV" -o \
        -iname "* *.MKV" -o \
        -iname "* *.WMV" -o \
        -iname "* *_tmp" -o \
        -iname "* *_TMP" -o \
        -iname "* *_Tmp" -o \
        -iname "*_*" \
    \) | wc -l)

    # 1. แปลง Path รูปแบบ Windows (F:\...) ให้เป็น WSL (/mnt/f/...) อัตโนมัติ
    if [[ "$src" =~ ^[a-zA-Z]:\\ ]]; then
        src="$(wslpath -u "$src" 2>/dev/null || echo "$src")"
    fi

    if [[ "$dest" =~ ^[a-zA-Z]:\\ ]]; then
        dest="$(wslpath -u "$dest" 2>/dev/null || echo "$dest")"
    fi

    # 2. ตรวจสอบโฟลเดอร์ต้นทาง
    if [ ! -d "$src" ]; then
        cn r b "Error: Directory '$src' does not exist."
        return 1
    fi

    # 3. เคลียร์ช่องว่างในชื่อไฟล์ก่อน
    rename_sp "$src"

    # 4. ค้นหาไฟล์วิดีโอทั้งหมด
    local files=()

    mapfile -t files < <(find "$src" -type f \( \
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

    # 5. สร้างโฟลเดอร์ปลายทางถ้ายังไม่มี
    if [ ! -d "$dest" ]; then
        mkdir -p "$dest"
    fi

    # 6. เช็กว่าเจอไฟล์หรือไม่
    if [ "${#files[@]}" -eq 0 ]; then
        echo "No files found to move."
        return 0
    fi

    # 7. ย้ายไฟล์
    for f in "${files[@]}"; do
        [ -f "$f" ] || continue

        local file_name
        file_name="$(basename "$f")"

        mv "$f" "$dest/$file_name" \
            && cn 10 b "done moved $file_name" \
            || cn r b "cant moved $file_name"
    done
    c gr "" "ย้ายไฟล์แล้วทั้งหมด" ; c 10 b "$count" ; cn gr "" "files"
}

#-- version: Syncthing conflict resolver — newer mtime wins (พี่โจคนเดียวที่แก้)
#-- ใช้งาน: del_c [dir]  (default = $SSOT)
del_c(){
    local conf_dir=${1:-$SSOT}

    # Guard 1: dir ต้องมีอยู่จริง
    [[ -d "$conf_dir" ]] || { cn 196 b "✗ dir not found: $conf_dir"; return 1; }

    # เก็บ conflict files ทั้งหมดเป็น NUL-delimited array
    local -a files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$conf_dir" -type f -name "*.sync-conflict-2*" -print0)

    local total=${#files[@]}

    # ถ้าไม่เจอเลย ก็บอกแล้วจบ
    if [[ $total -eq 0 ]]; then
        cn 220 b "✓ no syncthing conflict files in $conf_dir"
        return 0
    fi

    cn 226 b "▶ Found $total syncthing conflict file(s). Analyzing mtime…"

    # ตัวแปรสะสมผลลัพธ์
    local promoted=0 deleted=0 skipped=0 failed=0
    local -a plan_lines=()

    for cf in "${files[@]}"; do
        local dir bn orig orig_path
        dir="$(dirname "$cf")"
        bn="$(basename "$cf")"

        # ตัด suffix .sync-conflict-<timestamp>-<DEVICEID>.<ext>
        # Pattern Syncthing: <orig>.sync-conflict-20260818-102423-3S42YWK.log
        # ใช้ sed: ตัดจาก ".sync-conflict-" เป็นต้นไป รวม timestamp + device id
        # แต่ ext ของ orig อาจจะอยู่หลัง timestamp+deviceid ก็ได้ ดังนั้นใช้ regex ที่รู้ device id format
        # device id = [A-Z0-9]{6,8} (uppercase alphanumeric)
        orig="$(printf '%s' "$bn" | sed -E 's/\.sync-conflict-[0-9]{8}-[0-9]{6}-[A-Z0-9]+\././')"

        # fallback: ถ้า orig เหมือนเดิม (pattern ไม่ match) → ลบ conflict copy อย่างเดียว
        if [[ "$orig" == "$bn" ]]; then
            plan_lines+=("  [SKIP]  $cf  (cannot parse original name)")
            ((skipped++))
            continue
        fi

        orig_path="$dir/$orig"

        # เคส A: ไม่มี original → conflict copy คือของจริง → promote
        if [[ ! -f "$orig_path" ]]; then
            plan_lines+=("  [PROMOTE]  $cf  →  $orig_path  (no original found)")
            ((promoted++))
            continue
        fi

        # เคส B: มี original → เทียบ mtime
        local cf_m orig_m
        cf_m=$(stat -c %Y "$cf" 2>/dev/null)
        orig_m=$(stat -c %Y "$orig_path" 2>/dev/null)

        if (( cf_m > orig_m )); then
            plan_lines+=("  [PROMOTE]  $cf  (newer)  →  $orig_path  |  orig mtime: $(date -d @"$orig_m" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)  conflict mtime: $(date -d @"$cf_m" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)")
            ((promoted++))
        elif (( orig_m > cf_m )); then
            plan_lines+=("  [DELETE]  $cf  (older)  |  orig mtime: $(date -d @"$orig_m" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)  conflict mtime: $(date -d @"$cf_m" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)")
            ((deleted++))
        else
            plan_lines+=("  [SKIP]  $cf  (same mtime as orig — keep both, manual check needed)")
            ((skipped++))
        fi
    done

    # แสดง plan ทั้งหมด
    printf '%s\n' "${plan_lines[@]}"

    # สรุปตัวเลข
    echo ""
    c 10 b "  Plan: "; c 45 b "$promoted"; c 10 b " promote, "; c 45 b "$deleted"; c 220 b " delete, "; c 45 b "$skipped"; c 220 b " skip"
    echo ""

    # ถ้าทุกอันถูก skip → จบเลย
    if (( promoted == 0 && deleted == 0 )); then
        cn 220 b "→ nothing to do (all skipped)"
        return 0
    fi

    # Guard 2: ถามยืนยัน
    c 11 b "? Execute this plan? [y/N] "
    local ans
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || { cn 220 b "→ cancelled (nothing changed)"; return 0; }

    # Execute plan
    local idx=0
    for cf in "${files[@]}"; do
        local line="${plan_lines[$idx]}"
        ((idx++))

        if [[ "$line" == *"[SKIP]"* ]]; then
            continue
        elif [[ "$line" == *"[PROMOTE]"* ]]; then
            local dir bn orig orig_path
            dir="$(dirname "$cf")"
            bn="$(basename "$cf")"
            orig="$(printf '%s' "$bn" | sed -E 's/\.sync-conflict-[0-9]{8}-[0-9]{6}-[A-Z0-9]+\././')"
            orig_path="$dir/$orig"

            # ถ้ามี original อยู่ → ลบ original ก่อน แล้วค่อย rename conflict → original
            if [[ -f "$orig_path" ]]; then
                rm -f -- "$orig_path" || { ((failed++)); cn 196 b "✗ cant remove old: $orig_path"; continue; }
            fi
            if mv -f -- "$cf" "$orig_path" 2>/dev/null || (rm -f -- "$orig_path" 2>/dev/null; mv -f -- "$cf" "$orig_path"); then
                c 10 b "  ✓ promoted: "; c 220 b "$cf"; cn 10 b "  →  "; c 45 b "$orig_path"
            else
                ((failed++))
                cn 196 b "✗ cant promote: $cf → $orig_path"
            fi
        elif [[ "$line" == *"[DELETE]"* ]]; then
            if rm -f -- "$cf"; then
                c 10 b "  ✓ deleted: "; c 220 b "$cf"
            else
                ((failed++))
                cn 196 b "✗ cant remove: $cf"
            fi
        fi
    done

    # สรุป
    echo ""
    if [[ $failed -eq 0 ]]; then
        c 10 b "✓ Done: "; c 45 b "$promoted"; c 10 b " promoted, "; c 45 b "$deleted"; c 10 b " deleted"
        [[ $skipped -gt 0 ]] && { c 220 b ", "; c 45 b "$skipped"; cn 220 b " skipped (manual check)"; } || echo ""
    else
        c 10 b "⚠ Done with errors: "; c 45 b "$failed"; cn 196 b " failed"
        return 1
    fi
}


wa() {
    ffmpeg -hide_banner -stats \
        -i "$1" \
        -vf scale=-2:480 \
        -c:v libx264 \
        -preset veryfast \
        -crf 28 \
        -c:a aac -b:a 96k \
        "${1%.*}_wa.mp4"
}


# g — quick git shortcut (พี่โจใช้บ่อย)
#   g                  → if dirty: commit+(optional msg)+pull --rebase+push, else just pull --rebase+push
#   g "<msg>"          → commit -m "<msg>" + pull --rebase + push
#   g s | status       → git status
#   g c "<msg>" | commit "<msg>"  → commit only
#   g a | add          → git add -A
#   g p | push         → git push
#   g pl | pull        → git pull --rebase
#   g pln | pulln      → git pull --no-rebase
#   g d | diff         → git diff --stat
#   g l | log          → git log --oneline -10
#   g <other>          → pass through to git
#
# Safety: ถ้า no-arg + dirty working tree → ถามก่อน commit
g() {
    local repo="${SSOT:-$HOME/bashscripts}"
    [[ -d "$repo" ]] || { cn 196 b "✗ repo not found: $repo"; return 1; }
    cd "$repo" || return 1

    # ถ้าไม่มี args → commit+push (ถ้ามี change) หรือ push only
    if (( $# == 0 )); then
        if ! git diff --quiet HEAD 2>/dev/null || [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
            c 11 b "? Working tree dirty — commit with $(c 220 b 'date')? [y/N] "
            local ans; read -r ans
            [[ "$ans" =~ ^[Yy]$ ]] || { cn 220 b "→ cancelled"; return 0; }
            git add -A && git commit -m "$(date '+%Y-%m-%d %H:%M:%S')"
        fi
        git_ push
        return $?
    elif (( $# == 1 )); then
        git_ all "$1"
    else
    # มี args → ส่งต่อไป git_ (ซึ่งรู้จัก s/c/a/all/push/pull ฯลฯ)
         git_ "$@"       
    fi

 
}replace_w() {
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

replace_w2() {
    local old_name=${1:-}
    local new_name=${2:-}
    local target=${3:-$PWD}

    # 1. ตรวจสอบว่ากรอกค่าคำเดิมและคำใหม่มาครบไหม
    if [[ -z "$old_name" || -z "$new_name" ]]; then
        echo "Usage: replace_w <old_name> <new_name> [target_folder]"
        return 1
    fi

    echo "🔍 Searching for '$old_name' in $target..."

    # 2. ค้นหาไฟล์ที่เจอคำนี้ พร้อมเก็บรายชื่อไว้ในตัวแปร array (ซ่อนไฟล์ขยะ/โฟลเดอร์ระบบ เช่น .git เพื่อความสะอาด)
    # ใช้ mapfile เพื่อดึงผลลัพธ์จาก grep มาเก็บเป็นอาเรย์
    local files=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && files+=("$file")
    done < <(grep -rl --exclude-dir={.git,node_modules} "$old_name" "$target" 2>/dev/null)

    # 3. ถ้าไม่พบไฟล์เลย ให้แจ้งเตือนและจบการทำงาน
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "❌ No files found containing '$old_name'."
        return 0
    fi

    # 4. แสดงรายชื่อไฟล์ที่เจอทั้งหมด
    echo ""
    echo "📄 Found ${#files[@]} file(s) to update:"
    for f in "${files[@]}"; do
        echo "   - $f"
    done
    echo ""

    # 5. ถามยืนยันความปลอดภัย (y/n)
    read -p "❓ Do you want to replace '$old_name' with '$new_name' in these files? (y/N): " confirm
    
    # แปลงคำตอบเป็นตัวพิมพ์เล็กทั้งหมด เพื่อให้กด Y หรือ y ก็ได้
    confirm=${confirm,,}

    if [[ "$confirm" != "y" ]]; then
        echo "🛑 Operation cancelled."
        return 0
    fi

    echo "🔄 Replacing..."

    # 6. ทำการแทนที่คำในไฟล์ที่คัดกรองมาแล้ว
    for f in "${files[@]}"; do
        sed -i "s/${old_name}/${new_name}/g" "$f"
    done

    echo "✨ All done!"
}

replace_w3() {
    local old_name=${1:-}
    local new_name=${2:-}
    local target=${3:-$PWD}

    # 1. ตรวจสอบว่ากรอกค่าคำเดิมและคำใหม่มาครบไหม
    if [[ -z "$old_name" || -z "$new_name" ]]; then
        echo "Usage: replace_w <old_name> <new_name> [target_folder]"
        return 1
    fi

    echo "🔍 Searching for '$old_name' in $target..."

    # 2. ค้นหาไฟล์ที่เจอคำนี้ พร้อมเก็บรายชื่อไว้ในตัวแปร array (ซ่อนไฟล์ขยะ/โฟลเดอร์ระบบ เช่น .git เพื่อความสะอาด)
    # ใช้ mapfile เพื่อดึงผลลัพธ์จาก grep มาเก็บเป็นอาเรย์
    local files=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && files+=("$file")
    done < <(grep -rl --exclude-dir={.git,node_modules} "$old_name" "$target" 2>/dev/null)

    # 3. ถ้าไม่พบไฟล์เลย ให้แจ้งเตือนและจบการทำงาน
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "❌ No files found containing '$old_name'."
        return 0
    fi

    # 4. แสดงรายชื่อไฟล์ที่เจอทั้งหมด
    echo ""
    echo "📄 Found ${#files[@]} file(s) to update:"
    for f in "${files[@]}"; do
        echo "   - $f"
    done
    echo ""

    # 5. ถามยืนยันความปลอดภัย (y/n)
    read -p "❓ Do you want to replace '$old_name' with '$new_name' in these files? (y/N): " confirm
    
    # แปลงคำตอบเป็นตัวพิมพ์เล็กทั้งหมด เพื่อให้กด Y หรือ y ก็ได้
    confirm=${confirm,,}

    if [[ "$confirm" != "y" ]]; then
        echo "🛑 Operation cancelled."
        return 0
    fi

    echo "🔄 Replacing..."

    # 6. ทำการแทนที่คำในไฟล์ที่คัดกรองมาแล้ว
    for f in "${files[@]}"; do
        sed -i "s/${old_name}/${new_name}/g" "$f"
    done

    echo "✨ All done!"
}
multi_w() {
    # 1. เช็กว่ามีการส่ง Parameter มาอย่างน้อย 1 ตัวไหม
    if [[ $# -lt 1 ]]; then
        echo "Usage: replace_w <old1=new1> [old2=new2 ...] [target_folder]"
        echo "Example: replace_w \"cat=dog\" \"apple=banana\" ./my_folder"
        return 1
    fi

    local pairs=()
    local target="$PWD"

    # 2. แยกแยะระหว่าง "คู่คำ" กับ "target_folder"
    # ถ้า Parameter ตัวสุดท้ายไม่ใช่รูป pattern "X=Y" และเป็นโฟลเดอร์/ไฟล์ที่มีอยู่จริง ให้ถือว่าเป็น target
    local last_arg="${!#}"
    if [[ ! "$last_arg" =~ = ]] && [[ -e "$last_arg" ]]; then
        target="$last_arg"
        pairs=("${@:1:$#-1}") # เอา Parameter ทุกตัวยกเว้นตัวสุดท้าย
    else
        pairs=("$@")         # เอา Parameter ทั้งหมดเป็นคู่คำ
    fi

    # 3. ตรวจสอบรูปแบบ Input ของคู่คำ
    local old_words=()
    local new_words=()

    for pair in "${pairs[@]}"; do
        if [[ ! "$pair" =~ = ]]; then
            echo "❌ Error: Invalid format '$pair'. Must be 'old=new'"
            return 1
        fi
        old_words+=("${pair%%=*}") # ดึงข้อความหน้าเครื่องหมาย =
        new_words+=("${pair#*=}")  # ดึงข้อความหลังเครื่องหมาย =
    done

    echo "🔍 Target Directory: $target"
    echo "📋 Replacement Pairs:"
    for i in "${!old_words[@]}"; do
        echo "   - '${old_words[$i]}' ➡️ '${new_words[$i]}'"
    done
    echo "------------------------------------------------"

    # 4. ค้นหาไฟล์ที่มีคำใดคำหนึ่งในรายการ
    local matched_files=()
    local grep_pattern=""

    # สร้าง pattern สำหรับ grep เช่น "word1\|word2"
    for word in "${old_words[@]}"; do
        grep_pattern+="${word}\|"
    done
    grep_pattern="${grep_pattern%\|}" # ตัด \| ตัวสุดท้ายออก

    while IFS= read -r -d '' file; do
        matched_files+=("$file")
    done < <(find "$target" -type f -exec grep -l "$grep_pattern" {} + 2>/dev/null)

    # 5. เช็กว่าเจอไฟล์หรือไม่
    if [[ ${#matched_files[@]} -eq 0 ]]; then
        echo "❌ No matching files found."
        return 0
    fi

    # 6. แสดงรายการไฟล์ที่ค้นพบ
    echo "Found '${#matched_files[@]}' file(s):"
    for file in "${matched_files[@]}"; do
        echo "  - $file"
    done
    echo "------------------------------------------------"

    # 7. ถามยืนยัน Y/N
    local confirm
    read -rp "Proceed with replacement in these files? (y/N): " confirm

    # 8. ทำการเปลี่ยนคำทุกคู่ในไฟล์ที่เจอ
    case "$confirm" in
        [yY]|[yY][eE][sS])
            echo "🚀 Replacing..."
            for file in "${matched_files[@]}"; do
                for i in "${!old_words[@]}"; do
                    # ใช้ # เป็น Delimiter แทน / ป้องกันปัญหาเรื่อง path/URL
                    sed -i "s#${old_words[$i]}#${new_words[$i]}#g" "$file"
                done
            done
            echo "✨ All done!"
            ;;
        *)
            echo "🛑 Operation cancelled."
            return 0
            ;;
    esac
}
change_w() {

    replace_w2 "${2:-}" "${3:-}" "${1:-$PWD}"
    if [[ "$4" != "" ]] && [[ "$5" != "" ]]; then 
        replace_w3 "$4" "$5" "${1:-$PWD}"
    fi
    if [[ "$6" != "" ]] && [[ "$7" != "" ]]; then
        replace_w2 "$6" "$7" "${1:-$PWD}"
    fi
    if [[ "$8" != "" ]] && [[ "$9" != "" ]]; then
        replace_w3 "$8" "$9" "${1:-$PWD}"
    fi
   

}

