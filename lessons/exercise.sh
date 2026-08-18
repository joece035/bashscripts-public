conf_del(){
    local conf_dir=${1:-$SSOT}
    
    # ค้นหาไฟล์แล้วเก็บเข้าตัวแปร
    local conf_files
    conf_files=$(find "$conf_dir" -type f -iname "*conflict*")
    
    # 1. เช็คว่าถ้าไม่พบไฟล์ ให้แจ้งเตือนแล้วจบการทำงานทันที
    if [[ -z "$conf_files" ]]; then
        cn 198 bi "not found any conflict files"
        return 1
    fi
    
    # 2. นับจำนวนไฟล์จากตัวแปรที่มีอยู่แล้ว (ใช้วิธีนับจำนวนบรรทัด)
    local files_count
    files_count=$(wc -l <<< "$conf_files")
    
    # 3. ลบไฟล์อย่างปลอดภัย (รับมือกับไฟล์ที่มีเว้นวรรคได้)
    while IFS= read -r file; do
        rm -f "$file"
    done <<< "$conf_files"

     c 10 bi "all"; c 45 bi "$files_count"; cn 10 bi "conflict files are removed"
}


