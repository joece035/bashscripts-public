#!/bin/bash
# ============================================================
#----------PHAT FOR FUNCTION----------#
  export FUNC_DIR="$SCRIPTS_PATH/functions"
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
# fn j <file>         → $SSOT/joe.learn/<file>

#--------------------------------------#   
cdc() {
   
   cn lg b  "$(cd "$@" && pwd)" 
}
#--------------------------------------#
fn() {
  local j=$(echo "$SSOT/functions/00.1-function-tools.sh")
  local jb="$(dirname $j)/joe-block/entry.sh"
  case "$1" in
    j)
      if (( $# >= 2 )); then
        printf '%s\n' "$SSOT/joe.learn/$2"   # fn j <file> → $SSOT/joe.learn/<file>
      else
        printf '%s' "$j"
      fi
      ;;
    jb) source "$jb" ;;
    *) 
      if (( $# == 0 )); then
        printf '%s' "$SSOT/functions"
      else
        printf '%s\n' "$SSOT/functions/$@"
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

ssh_kadd(){
  #-- function นี้เอาไว้เวลาที่ต้องการจะเพิ่ม public ssh key เครื่องที่ต้องการเชื่อมไป ลงในไฟล์ authorized_keys
  #-- public ssh key ที่ต้องการจะเพิ่ม รัน cat ~/.ssh/id_ed25519.pub ที่เครื่องปลายทาง แล้ว copy มา
    local pubkey="${1:?SELECT PUBLIC KEY}"
    [[ -d $HOME/.ssh ]] || mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    echo "${pubkey}" >> "$HOME/.ssh/authorized_keys" &&
    chmod 600 "$HOME/.ssh/authorized_keys"
    echo "done adding ssh key" 
}