#!/bin/bash

# ==========================================
# 1. นิยามฟังก์ชัน _check() (เวอร์ชัน Cross-Shell)
# ==========================================
_check() {
    local type="${1:--f}"
    local tar_input="${2:-}"
    local cmd="${3:-source}"
    shift 3

    if declare -p "$tar_input" 2>/dev/null | grep -E -q '(declare|typeset) -[aA]'; then
        local -a items=()

        if [ -n "$ZSH_VERSION" ]; then
            items=("${(@)${(P)tar_input}}")
        else
            local -n ref="$tar_input"
            items=("${ref[@]}")
        fi

        for item in "${items[@]}"; do
            test "$type" "$item" && "$cmd" "$item" "$@"
        done
    else
        test "$type" "$tar_input" && "$cmd" "$tar_input" "$@"
    fi
}

# ==========================================
# 2. Logic สำหรับการทดสอบ (Test Suite)
# ==========================================
run_test_suite() {
    echo "=========================================="
    echo " 🚀 Running tests in: $(basename "$SHELL") (Version: ${BASH_VERSION:-$ZSH_VERSION})"
    echo "=========================================="

    # สร้างไฟล์จำลองสำหรับทดสอบ
    touch /tmp/test_file_a.txt /tmp/test_file_b.txt

    # --- Test Case 1: ทดสอบส่งแบบ ไฟล์เดี่ยว (String) ---
    echo -n "[Test 1] Single File Check: "
    _check -f "/tmp/test_file_a.txt" echo "FOUND"

    # --- Test Case 2: ทดสอบส่งแบบ Array ---
    local test_list=("/tmp/test_file_a.txt" "/tmp/test_file_b.txt" "/tmp/non_exist_file.txt")
    echo "[Test 2] Array Check (Should find 2 files):"
    _check -f test_list echo " -> Loaded:"

    # ลบไฟล์จำลองหลังทดสอบเสร็จ
    rm -f /tmp/test_file_a.txt /tmp/test_file_b.txt
    echo ""
}

# ==========================================
# 3. รันเทียบทั้ง Bash และ Zsh
# ==========================================
# ถ้าเป็นการสั่งรันสคริปต์ตรงๆ ให้รัน Test Suite
run_test_suite