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

#-- version ใช้ find -delete
conf_del(){
    local conf_dir=${1:-$SSOT}
    local files_count=0
    local conf_names=$(find "$conf_dir" -type f -iname "*conflict*" -exec basename "{}" ;)
    # ค้นหาและนับจำนวนไฟล์ก่อน
    files_count=$(find "$conf_dir" -type f -iname "*conflict*" | wc -l)
    
    # ถ้าจำนวนเป็น 0 ให้เด้งออกเลย
    if [[ $files_count -eq 0 ]]; then
        #cn 198 bi "not found any conflict files"
        return 1
    fi
    
    # ให้ find ลบไฟล์ทั้งหมดในคำสั่งเดียว (รองรับเว้นวรรคและชื่อแปลกๆ ได้ 100%)
    find "$conf_dir" -type f -iname "*conflict*" -delete

    #c 10 bi "all"; c 45 bi "$files_count"; cn 10 bi "conflict files are removed"
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


g() {
    if (( $# <= 1 )); then
        git_ all "${1:-$(date)}"
    else
        git_ "$@"
    fi
}