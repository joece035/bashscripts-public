#!/bin/bash
ssh_setup() {
  local t=$1
      case $t in
          gen)
             local comment=${2:-}
              mkdir -p "$HOME/.ssh"
              ssh-keygen -t ed25519 -C 
              "$comment" &&
               cat ~/.ssh/id_ed25519.pub
               ;;
          add)
              local key=${2:-}
              mkdir -p ~/.ssh
              echo "$key" >> ~/.ssh/authorized_keys &&
              chmod 700 ~/.ssh &&
              chmod 600 ~/.ssh/authorized_keys &&
              echo "DONE ADDING PUBKEY"
              ;;
          *)
              echo "unknown agrument" && return 1
              ;;
      esac      
  }

kgen() {
  local machine="${1:-}"

  # 1. เช็คว่าใส่ชื่อ identifier ไหม
  if [[ -z "$machine" ]]; then
    echo "Error: Please specify machine/identifier name."
    echo "Usage: ssh_kgen <identifier_name>"
    return 1
  fi

  local keyfile="$HOME/.ssh/id_ed25519_${machine}"

  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # 2. สร้าง Key ถ้ายังไม่มี
  if [[ -f "$keyfile" ]]; then
    echo "SSH key already exists at: $keyfile"
  else
    ssh-keygen -t ed25519 -C "${machine}" -f "${keyfile}" -N ""
    echo "Generated new SSH key: $keyfile"
  fi

  # 3. ตั้งค่า Permission
  chmod 600 "${keyfile}"
  chmod 644 "${keyfile}.pub"

  # 4. จัดการ ssh-agent
  if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" >/dev/null
  fi

  # 5. โหลด Key เข้า Agent
  ssh-add "${keyfile}" 2>/dev/null

  # 6. ก๊อปปี้ Public Key
  local pub_key
  pub_key=$(cat "${keyfile}.pub")

  cb_copy "$pub_key"
  echo "----------------------------------------------------"
  echo "Copied public key to clipboard:"
  echo "$pub_key"
  echo "----------------------------------------------------"
  echo "Done! Paste this public key into your remote service/server."
}