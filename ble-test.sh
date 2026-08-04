#!/usr/bin/env bash
# ไฟล์ทดสอบชั่วคราว: ตรวจว่า ble.sh โหลดและทำงานได้
echo "flags: $-"
source ~/.local/share/blesh/ble.sh --lib
echo "RC=$?"
sleep 1
echo "VERSION=$_ble_version"
echo "cmds: $(command -v ble-attach bleopt ble-face)"
echo "ble functions: $(declare -F | grep -c '^ble/')"
