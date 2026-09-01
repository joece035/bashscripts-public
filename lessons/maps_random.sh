#!/bin/bash
maps=("SKY" "FIRE" "WATER" "WIND")

random_map1() {
    # รับค่าจาก Argument หรือใช้ค่า Default ถ้าไม่ได้ระบุ
    
    local -a maps=("${@}")
    if (( ${#maps[@]} == 0 )); then
        maps=("Dust II" "Inferno" "Mirage" "Nuke" "Overpass" "Ancient" "Anubis")
    fi

    local n=${#maps[@]}
    local i j tmp

    # Fisher-Yates: สลับตำแหน่งแบบสุ่มจากหลังมาหน้า
    for (( i = n - 1; i > 0; i-- )); do
        j=$(( RANDOM % (i + 1) ))
        tmp="${maps[i]}"
        maps[i]="${maps[j]}"
        maps[j]="$tmp"
    done

    # แสดงผลตามลำดับที่สุ่มแล้วจนครบ
    for m in "${maps[@]}"; do
        cn 10 b "🎲 $m"
    done
}

random_map2() {
    local -a maps=("${@}")
    if (( ${#maps[@]} == 0 )); then
        maps=("Dust II" "Inferno" "Mirage" "Nuke" "Overpass" "Ancient" "Anubis")
    fi

    while IFS= read -r m; do
        cn 10 b "🎯 $m"
    done < <(shuf -e "${maps[@]}")
}