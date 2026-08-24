#!/bin/bash

# 1. ฟังก์ชันคำนวณพื้นที่ว่าง (หน่วย KB)
get_free_space() {
    df / --output=avail | tail -n 1 | tr -d ' '
}

echo "=========================================="
echo "    เริ่มกระบวนการทำความสะอาดระบบ"
echo "=========================================="

# บันทึกพื้นที่ว่างก่อนลบ
BEFORE_KB=$(get_free_space)

# แสดงพื้นที่ดิสก์ก่อนลบ (อ่านง่าย)
echo -n "พื้นที่ว่างก่อนทำความสะอาด: "
df -h / | awk 'NR==2 {print $4}'
echo "------------------------------------------"

# 2. เริ่มล้างขยะ
echo "[1/4] ล้างแคช APT Packages..."
sudo apt-get clean > /dev/null 2>&1

echo "[2/4] ลบโปรแกรมขยะที่ไม่ได้ใช้ (Autoremove)..."
sudo apt-get autoremove -y > /dev/null 2>&1

echo "[3/4] ล้าง User Cache (~/.cache)..."
rm -rf ~/.cache/* > /dev/null 2>&1

echo "[4/4] ล้าง System Temp (/tmp)..."
sudo rm -rf /tmp/* > /dev/null 2>&1

# 3. คำนวณผลลัพธ์
AFTER_KB=$(get_free_space)
FREED_KB=$((AFTER_KB - BEFORE_KB))

echo "------------------------------------------"
# แสดงพื้นที่ว่างหลังลบ
echo -n "พื้นที่ว่างหลังทำความสะอาด: "
df -h / | awk 'NR==2 {print $4}'

# แปลงหน่วย KB เป็น MB หรือ GB เพื่อความอ่านง่าย
if [ "$FREED_KB" -gt 0 ]; then
    if [ "$FREED_KB" -ge 1048576 ]; then
        FREED_GB=$(awk "BEGIN {printf \"%.2f\", $FREED_KB/1048576}")
        echo -e "\n🎉 สำเร็จ! คุณได้พื้นที่คืนมาทั้งหมด: \032[1;32m${FREED_GB} GB\033[0m"
    else
        FREED_MB=$(awk "BEGIN {printf \"%.2f\", $FREED_KB/1024}")
        echo -e "\n🎉 สำเร็จ! คุณได้พื้นที่คืนมาทั้งหมด: \032[1;32m${FREED_MB} MB\033[0m"
    fi
else
    echo -e "\n✨ ระบบสะอาดอยู่แล้ว ไม่พบขยะเพิ่มครับ!"
fi
echo "=========================================="