# ============================================================
# SupperBoom env function (moved from 00-env.sh)
# ============================================================

# ============================================================
# Boom env function (moved from 00-env.sh)
# ============================================================
_() {
   local base_c="${WIN_PATH}c/Users/User/Documents/mumusharedfolder"
   local base_z="${WIN_PATH}z/MuMuSharedFolder"
   local base_backup="${WIN_PATH}h/boom"
   local base_hb="${WIN_PATH}h/MuMuSharedFolder"
   list_=(
        "css|"${base_c}/Screenshots""
        "cvdo|"${base_c}/VideoRecords""
        "hss|"${base_hb}/Screenshots""
        "hvdo|"${base_hb}/VideoRecords""
        "bss|"${base_backup}/Screenshots""
        "bvdo|"${base_backup}/VideoRecords""
        "zss|"${base_z}/Screenshots"
        "zvdo|${base_z}/VideoRecords"
        "h|"--help"
      ) 
   case $1 in
      css)         printf "%s\n" "${base_c}/Screenshots" ;;
      cvdo)        printf "%s\n" "${base_c}/VideoRecords" ;;
      hss)         printf "%s\n" "${base_hb}/Screenshots" ;;
      hvdo)        printf "%s\n" "${base_hb}/VideoRecords" ;;
      bss)         printf "%s\n" "${base_backup}/Screenshots" ;;
      bvdo)        printf "%s\n" "${base_backup}/VideoRecords" ;;
      zss)         printf "%s\n" "${base_z}/Screenshots" ;;
      zvdo)        printf "%s\n" "${base_z}/VideoRecords" ;;
      -h|--help)   bn_2 "${list_[@]}" ;;
      *)           bn_2 "${list_[@]}" ;;
   esac
}



n_(){
	 local border_len=83 term_w
	 term_w=$(tput cols)
	 ((border_len > term_w)) && border_len=$term_w
     local border="$(cn 92 b "$(draw_ '▬' "$border_len")")"
	 local text="Current System Information"
     local head="$(cn 208 b "$text")"
     local banner=""
	 local pad_=$(((border_len - ${#text})/2))

     banner+="${border}\n"
     banner+="$(printf " %*s$head%*s\n" "$pad_" ' ' "$pad_" ' ')\n"
     banner+="${border}\n"
     banner+="$(cn 250 d "Current Directory")         : $(cn lcr '' "${PWD}")\n"
     banner+="$(cn 250 d "Home Directory")            : $(cn lcr '' "${HOME}")\n"
     banner+="$(cn 250 d "Current User")              : $(cn lcr '' "${USER}")\n"
     banner+="$(cn 250 d "Current Shell")             : $(cn lcr '' "${SHELL}")\n"
     banner+="$(cn 250 d "Current Kernel")            : $(cn lcr '' "$(uname -r)")\n"
     banner+="$(cn 250 d "Current Architecture")      : $(cn lcr '' "$(uname -m)")\n"
     banner+="$(cn 250 d "Current OS")                : $(cn lcr '' "$(uname -o)")\n"
     banner+="$(cn 250 d "Current OS Version")        : $(cn lcr '' "$(uname -v)")\n"
     banner+="$(cn 250 d "Current OS Platform")       : $(cn lcr '' "$(uname -s)")\n"
     banner+="$(cn 250 d "Current OS Kernel Version") : $(cn lcr '' "$(uname -r)")\n"
     banner+="${border}\n"

     printf "%b\n" "${banner}"

   } 


# ============================================================
# Banner / Info Card Template (Reusable)
# ============================================================
bn_2() {
   # --- 1. Config & Defaults ---
   local title="${BN_TITLE:-Shortcuts folders}"
   local title_c="${BN_TITLE_COLOR:-208}"      # ส้ม
   local title_s="${BN_TITLE_STYLE:-b}"        # bold

   local border_ch="${BN_BORDER_CHAR:-▬}"
   local border_c="${BN_BORDER_COLOR:-92}"     # ม่วง/น้ำเงิน
   local border_s="${BN_BORDER_STYLE:-b}"
   local border_len="${BN_BORDER_LEN:-}"

   local label_c="${BN_LABEL_COLOR:-250}"      # เทาสว่าง
   local label_s="${BN_LABEL_STYLE:-d}"        # dim
   local val_c="${BN_VAL_COLOR:-lcr}"          # light color / dynamic
   local val_s="${BN_VAL_STYLE:-}"
   local sep="${BN_SEP:- : }"

   local term_w
   term_w=$(tput cols 2>/dev/null || echo 80)

   # --- 2. Scan หา max label & max value ---
   local item lbl val padded_lbl
   local max_label_len=0 max_val_len=0

   for item in "$@"; do
       lbl="${item%%|*}"
       val="${item#*|}"
       (( ${#lbl} > max_label_len )) && max_label_len=${#lbl}
       (( ${#val} > max_val_len )) && max_val_len=${#val}
   done

   # คำนวณความกว้าง Border
   local content_w=$(( max_label_len + ${#sep} + max_val_len ))
   local title_len=${#title}

   if [[ -z "$border_len" || "$border_len" -eq 0 ]]; then
       border_len=$content_w
       (( title_len > border_len )) && border_len=$title_len
   fi

   (( border_len > term_w )) && border_len=$term_w
   (( border_len < 10 )) && border_len=10

   # --- 3. สร้าง Border & Header ---
   local border_raw="$(draw_ "$border_ch" "$border_len")"
   local border
   border="$(c "$border_c" "$border_s" "$border_raw")"

   # คำนวณการจัดกึ่งกลาง Title
   local pad_left=$(( (border_len - title_len) / 2 ))
   (( pad_left < 0 )) && pad_left=0

   # พิมพ์หัวตาราง
   printf "%s\n" "$border"
   if [[ -n "$title" ]]; then
      printf "%*s%s\n" "$pad_left" "" "$(c "$title_c" "$title_s" "$title")"
      printf "%s\n" "$border"
   fi

   # --- 4. แสดงผลข้อมูลแต่ละแถว ---
   for item in "$@"; do
       lbl="${item%%|*}"
       val="${item#*|}"
       printf -v padded_lbl "%-*s" "$max_label_len" "$lbl"
       c "$label_c" "$label_s" "$padded_lbl"
       printf "%s" "$sep"
       cn "$val_c" "$val_s" "$val"
   done

   # --- 5. พิมพ์ปิดท้าย ---
   printf "%s\n" "$border"
}
