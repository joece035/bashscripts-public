#!/bin/bash
# ============================================================
# ssh-config.sh — Multi-node Infrastructure (SSH · CONFIGURATIONs)
# ============================================================
# -- helper ssh setp
cb_read() {
  if command -v powershell.exe &>/dev/null; then
    powershell.exe -NoProfile -Command "Get-Clipboard" 2>/dev/null | tr -d '\r'
  elif command -v xclip &>/dev/null; then 
    xclip -selection clipboard -o 2>/dev/null
  elif command -v xsel &>/dev/null; then 
    xsel --clipboard --output 2>/dev/null
  fi
}
cb_copy() {
  local input="$1"
  if command -v powershell.exe &>/dev/null; then
    # ใช้ Set-Clipboard Direct ผ่าน PowerShell
    powershell.exe -NoProfile -Command "Set-Clipboard -Value '$input'" 2>/dev/null
  elif command -v xclip &>/dev/null; then 
    echo -n "$input" | xclip -selection clipboard
  elif command -v xsel &>/dev/null; then 
    echo -n "$input" | xsel --clipboard --input
  fi
}
ssh_kgen(){
  #-- สร้าง public/private key หากยังไม่มี
  local machine="${1:?Error: Please specify machine name (e.g. ssh_kgen my-server)}"
  local keyfile="$HOME/.ssh/id_ed25519_${machine}"

  if [[ -f "$keyfile" ]]; then
    echo "SSH key already exists at $keyfile"
  else
    # ใส่ -N "" เพื่อสร้าง Key แบบไม่มี passphrase ทันที ป้องกัน Script ค้างถาม
    ssh-keygen -t ed25519 -C "${machine}" -f "${keyfile}" -N ""
  fi

  local pub_key
  pub_key=$(cat "${keyfile}.pub")
  
  # คัดลอกลง Clipboard และแสดงผล
  cb_copy "$pub_key"
  echo "Copied to clipboard:"
  echo "$pub_key"
}
ssh_kadd(){
  #-- เพิ่ม Public Key ลงใน authorized_keys ของเครื่องปลายทาง (ป้องกันการเพิ่มซ้ำ)
  local pub_key="${1:-$(cb_read)}"
  local auth_file="$HOME/.ssh/authorized_keys"

  # ตรวจสอบว่ามีค่า Public Key ส่งมาจริงหรือไม่
  if [[ -z "$pub_key" ]]; then
    echo "Error: No public key provided or clipboard is empty." >&2
    return 1
  fi

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$auth_file"
  chmod 600 "$auth_file"

  # ตรวจสอบ Key ซ้ำ
  if grep -qF "$pub_key" "$auth_file"; then
    echo "Key already exists in $auth_file"
  else
    echo "$pub_key" >> "$auth_file"
    echo "Done: Added SSH key to $auth_file"
  fi
}
#-- all device publickey 
WSL_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZDIAdFwo+pfYQZh1Avii7BwUgYiL6UbljtmZwG8gM3 wsl"
TERMUX_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDcz/bCnmHnFAMnYaW9AEqdQlQWXYjG8UaUeUQ6cMtC termux" 
MUMU_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3BXYEuGAat94NgEfBo8CkcZGbkz1P5Lsnv6ANGW3oV mumu"
WINDOW_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHz2HO1nXny1R9+tOO92+3pRyLXmM1zz54pla0U3ENGi window"

# Helper สำหรับสั่ง Remote Command หรือ SSH เข้าเครื่องต่างๆ
ssh_() {
  local tar="$1"
  shift
    case "$tar" in
        t|tm|termux|TERMUX)     ssh termux "$@" ;;
        w|tw|window|win|WINDOW) ssh window "$@" ;;
        mm|mumu|MUMU)           ssh mumu "$@" ;;
        wsl|WSL|WSL2)           ssh wsl "$@" ;;
        *) cn r b "usage ssh_ <host>"; return 1 ;;
    esac     

}


 mkdir -p ~/.ssh && chmod 700 ~/.ssh
    echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYFfQQcdSRsjkZxbhTxhtqT/gbEhVlDqBfSbnREhtLI wsl-fresh-20260819' >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    cat ~/.ssh/authorized_keys