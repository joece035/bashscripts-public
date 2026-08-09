#!/bin/bash
# ============================================================
#----------PHAT FOR FUNCTION----------#
  export FUNC_DIR="$JOE_FUNCTIONS"
 #--------- FUNCTION FORM ------------#

#-------------------------------------#   
 
#-------PHAT FOR DASHBOARD ENGINE-----#  
ep() {
  printf '%s\n' "$ENGINES_DIR/${1:-""}"
 }
#--------------------------------------#   

#-------PHAT For HOME -----------------#  
hop() {
  printf '%s\n' "$home/${1:-""}"
}
#--------------------------------------#   

#-------PHAT For HOME -----------------#  
sd() {
  printf '%s\n' "$SDCARD_PATH/${1:-""}"
}
#--------------------------------------#   

#-------PHAT For FUNCTION/LEARN ------#  
# fn <file>           → $FUNC_DIR/<file>  (functions/)
# fn j <file>         → $JOE_ROOT/joe.learn/<file>

#--------------------------------------#   
cdc() {
   
   cn lg b  "$(cd "$@" && pwd)" 
}
#--------------------------------------#
fn() {
  local j=$(echo "$JOE_FUNCTIONS/00.1-function-tools.sh")
  local jb="$(dirname $j)/block_engine/entry.sh"
  case "$1" in
    j)
      if (( $# >= 2 )); then
        printf '%s\n' "$JOE_ROOT/joe.learn/$2"   # fn j <file> → $JOE_ROOT/joe.learn/<file>
      else
        printf '%s' "$j"
      fi
      ;;
    jb) source "$jb" ;;
    *) 
      if (( $# == 0 )); then
        printf '%s' "$JOE_FUNCTIONS"
      else
        printf '%s\n' "$JOE_FUNCTIONS/$@"
      fi
    ;;
  esac  
}
#----symbolic link----#
slink_() {
    # สลับไฟล์จริง(src)กับไฟล์ที่สร้างลิงก์ไปหา(tar) แล้วค่อยสร้างลิงก์ใหม่
    # กรณีไฟล์จริงอยู่บน termux ต้องการ link ไป sd card 
    local src="${1:?SELECT SOURCE}" #-- file จริงๆ
    local tar="${2:?SELECT TARGET}" #-- link ที่จะทำ
    cp -r "${src}" "${tar}" &&   #-- คัดลอกเนื้อหาไปใส่ไฟล์ปลายทางก่อน
    mv "${src}" "${src}.bk" &&  #-- backup file จริง
    ln -s "${tar}" "${src}" &&     #-- สร้าง symbolic link
    echo "done symbolic link $tar --> $src" 
    rm -rf "${src}.bk"            #-- ลบไฟล์สำรอง
    # -- ไฟล์จริงจะย้ายไปอยู่ใน sd card และสร้าง link มาแทนที่ตัวเอง
}


ssh_kgen_(){
  #-- สร้าง public/private key หากยังไม่มี
  local machine="${1:?SELECT machine}"
  local keyfile="$HOME/.ssh/id_ed25519_${machine}"
  
  if [[ -f "$keyfile" ]]; then
    echo "SSH key already exists at $keyfile"
  else
    ssh-keygen -t ed25519 -C "${machine}" -f "${keyfile}"
  fi
  cat "${keyfile}.pub"
}

ssh_kadd_(){
  #-- เพิ่ม Public Key ลงใน authorized_keys ของเครื่องปลายทาง (ป้องกันการเพิ่มซ้ำ)
  local pubkey="${1:?SELECT PUBLIC KEY}"
  local auth_file="$HOME/.ssh/authorized_keys"

  [[ -d "$HOME/.ssh" ]] || mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$auth_file"
  chmod 600 "$auth_file"

  if grep -qF "$pubkey" "$auth_file"; then
    echo "Key already exists in $auth_file"
  else
    echo "${pubkey}" >> "$auth_file"
    echo "done adding ssh key"
  fi
}
