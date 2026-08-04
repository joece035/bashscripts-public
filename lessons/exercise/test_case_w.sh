#!/bin/bash
# ============================================================
# test_case_w.sh  ไฟล์ สร้าง test scripts
# ============================================================
# HINTS สำหรับ พี่ Joe — เทียบกับ test_case_w_HINT.sh ข้าง ๆ ได้
#
# ❌ Bug ที่เจอ:
# 1) Nested function: bash ไม่มี nested function
#    → case1/case2/case3/case4 ที่ define ใน test_w() จะรันไม่ได้
# 2) `for _width_cal in ...` — loop variable ชนกับชื่อฟังก์ชัน _width_cal
#    → ทุก iteration จะรันฟังก์ชัน _width_cal ซ้ำ ๆ ไม่ใช่ 4 cases
# 3) `"$(case1)"` ใน array literal → รัน case1 ตอน array ถูกสร้าง
#    → ถ้า case1 ยังไม่ถูก declare (เพราะอยู่ใน scope) จะ "command not found"
# 4) `local case_rows=(...)` หลัง function definitions → ทำงานได้
#    แต่ structure มันสับสน — ปกติ local ควรอยู่ต้นฟังก์ชัน
# 5) `$_width_cal` (ไม่มี $()) — เป็นการ "run string as command"
#    → แต่ string มันคือ "_width_cal" ซึ่งตรงกับชื่อ function!
#
# ✅ แนวทาง (ดูตัวอย่างใน test_case_w_HINT.sh):
#   • แบบง่ายสุด: เรียก 4 cases เรียงกัน ไม่ต้อง loop
#   • แบบ array: เก็บ test input เป็น array แล้ว loop
#   • แบบ helper: สร้าง _run_case() แยก แล้วเรียก 4 ครั้ง
# ============================================================

test_w() {

    case1(){
    # เคส 1: จอกว้าง + _width_ ปกติ
    _width_=50; _max_label=10; _max_value=8
    _width_cal; echo "case 1: $_width_"  # ควรได้ 50
    }
    case2() {
    # เคส 2: _width_ เล็กไป
    _width_=10; _max_label=10; _max_value=8
    _width_cal; echo "case 2: $_width_"  # ควรถูกดันขึ้นเป็น min_w (34)
    }
    case3() {
    # เคส 3: _width_ ใหญ่เกิน
    _width_=200; _max_label=10; _max_value=8
    _width_cal; echo "case 3: $_width_"  # ควรถูกบีบลงเป็น max_w
    }
    case4() {
    # เคส 4: ไม่เคยตั้ง _width_
    unset _width_; _max_label=10; _max_value=8
    _width_cal; echo "case 4: $_width_"  # ⚠️ น่าจะพัง!
    }

    local case_rows=(
        "$(case1)" "$(case2)" "$(case3)" "$(case4)"
    )
        for _width_cal in "${case_rows[@]}"; do
            $_width_cal
            exercise_dashboard
            n s
        done
}


test_w_render() {

    local _width_cal_=("50" "10" "200" "")
    local i=0
    for width in "${_width_cal_[@]}"; do
        _width_=${width}
        echo "_width_=  $(cn 10 b "${width}")"
        _width_cal            # ← เพิ่ม: ต้องผ่าน clamp ก่อน
        _gen_border
        _center_cal
        _gen_frame
        # เอา exercise_dashboard ตัวแรกออก (ไม่มี input = no-op)
        exercise_dashboard <<'EOF'
🌍|JOE_ENV|WSL|📱
🔐|SSH|LOCAL|💻
🔄|SYNCTHING|ONLINE|🟢
EOF
        (( i++ ))
    done
}

test_offsets() {
    local offsets=(-1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1)
    for off in "${offsets[@]}"; do
        OFFSET="${off}"
        echo "=== OFFSET = ${off} ==="
        exercise_oc
    done
}



_center_cal_debug() {
    local _term_w max_indt min_indt=0 _indt _width_=50
    local off="${OFFSET:-0}"   # พิกัดฉาก: -1 (ซ้ายสุด), 0 (ตรงกลาง), 1 (ขวาสุด)
    
    _term_w=$(tput cols)

    local avail_space=$(( _term_w - _width_ ))
    (( avail_space < 0 )) && avail_space=0
    
    max_indt=$avail_space
    local mid_margin=$(( avail_space / 2 ))

    local _indt_raw
    _indt_raw=$(bc_ n "${mid_margin} + (${off} * ${mid_margin})")
    _indt=$(LC_ALL=C printf "%.0f" "${_indt_raw:-0}")

    (( _indt < min_indt )) && _indt=$min_indt
    (( _indt > max_indt )) && _indt=$max_indt

    printf -v _BLK_SP "%*s" "${_indt}" ""
    export _BLK_SP 

    printf '%s%s\n' "$_BLK_SP" "❤️❤️❤️ "

    local ROWS=(
      "|term_w|${_term_w}|"
      "|_indt|${_indt}|"
      "|OFFSET|${off}|"
      "|max_indt|${max_indt}|"
      "|min_indt|${min_indt}|"
      "|mid_margin|${mid_margin}|"
      "|avail_space|${avail_space}|"
      "|_width_|${_width_}|"
    )
    exercise_dashboard_array "${ROWS[@]}"
}
