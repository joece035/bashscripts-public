#!/bin/bash

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