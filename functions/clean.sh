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

move_() {
    local src="${1:-$video_p}"
    local dest="${2:-$bk_path}"

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

 
}