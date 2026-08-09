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
# fn j <file>         → $SSOT/joe.learn/<file>

#--------------------------------------#   
cdc() {
   
   cn lg b  "$(cd "$@" && pwd)" 
}
#--------------------------------------#
fn() {
  local j=$(echo "$JOE_FUNCTIONS/00.1-function-tools.sh")
  local jb="$JOE_PLUGINS/block_engine/entry.sh"
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
        printf '%s\n' "$JOE_FUNCTIONS/$@"
      fi
    ;;
  esac  
}


