#!/bin/bash
# ============================================================
# test_case_w.sh  ไฟล์ สร้าง test scripts
# ============================================================
# HINT FILE — ตัวอย่าง pattern ที่ถูกต้อง
# พี่ Joe ลองเทียบกับ test_case_w.sh ของพี่ดูทีละจุด
# ============================================================

# ⚠️ แนวคิดสำคัญของ bash function:
#   1) function ใน bash เป็น GLOBAL เสมอ (ไม่มี nested function)
#   2) local variable ต่างหากที่ local ได้
#   3) "$(func)" → รัน func ทันทีแล้วเอา stdout มาเก็บ
#   4) "case1" "case2" เป็นแค่ string → ต้องเอาไป eval หรือเรียกตรง ๆ

# 🐛 BUG ที่เจอตอนรันจริง:
#   case 4: _width_ unset → คาด 50 (fallback) แต่ได้ 34 (min_w)
#   สาเหตุ: (( _width_ > max_w )) ตอน _width_ ว่าง → bash เห็นเป็น 0
#   → 0 < 34 = true → ถูก clamp เป็น min_w ก่อนถึงบรรทัด fallback
#   แก้: ต้องตั้ง local _width_="${_width_:-50}" ในตอนต้นฟังก์ชัน _width_cal

# ---- แบบที่ 1: เรียกตรง ๆ ทีละ case (ง่ายสุด) ----
test_w_simple() {
    echo "=== Simple test (เรียกตรง) ==="

    _max_label=10
    _max_value=8

    # เคส 1
    _width_=50
    _width_cal
    echo "case 1: $_width_  (คาด 50)"

    # เคส 2
    _width_=10
    _width_cal
    echo "case 2: $_width_  (คาด min_w)"

    # เคส 3
    _width_=200
    _width_cal
    echo "case 3: $_width_  (คาด max_w = term_cols-2)"

    # เคส 4
    unset _width_
    _width_cal
    echo "case 4: $_width_  (คาด 50 จาก fallback)"
}

# ---- แบบที่ 2: ใช้ array เก็บ test data ----
test_w_array() {
    echo "=== Array test ==="

    local tests=(
        "50"    # case 1
        "10"    # case 2
        "200"   # case 3
        ""      # case 4 (unset)
    )
    local _max_label=10 _max_value=8
    local i=0

    for w in "${tests[@]}"; do
        ((i++))
        _width_="$w"        # ← กำหนดก่อนรัน
        _width_cal          # ← รันฟังก์ชันจริง
        echo "case $i: _width_=$_width_  (input was '$w')"
    done
}

# ---- แบบที่ 3: helper function ต่างหาก (global ไม่ซ้อนกัน) ----
_run_case() {
    # $1 = case num, $2 = input width
    _width_="$2"
    _width_cal
    echo "case $1: _width_=$_width_  (input '$2')"
}

test_w_helper() {
    echo "=== Helper test ==="
    _max_label=10
    _max_value=8

    _run_case 1 50
    _run_case 2 10
    _run_case 3 200
    _run_case 4 ""     # ส่ง "" → ใน _width_cal จะ ${_width_:-50}
}

# ============================================================
# 🎯 เจตนาของพี่ Joe:  อยากให้ test case 1-4 RENDER BLOCK ออกมาจริง
#
# ตัวอย่าง pattern (ลองเขียนเองใน test_case_w.sh):
#
#   test_w_render() {
#       _max_label=10
#       _max_value=8
#       local rows=("50" "10" "200" "")   # 4 _width_ values
#       local i=0
#       for w in "${rows[@]}"; do
#           ((i++))
#           _width_="$w"
#           _width_cal
#           _gen_border    # ← สร้าง border ตาม _width_ ใหม่
#           _center_cal
#           _gen_frame
#           echo "─── case $i: _width_=$_width_ (input '$w') ───"
#           exercise_dashboard <<<"🌍|JOE_ENV|WSL|📱"
#       done
#   }
#
# ลองทำเองดู แล้วส่ง output มาให้ดู — ถ้า block render ออกมา 4 แบบ
# แสดงว่าพี่เข้าใจ pipeline ทั้งหมดแล้ว 🎓
# ============================================================

# ---- เรียก test ----
#test_w_simple
#test_w_array
#test_w_helper
# test_w_render   # ← uncomment ตอนเขียนเสร็จ
