#!/bin/bash
# --- 1. Config & Defaults ---
 config_def() {

   set_ "BN_TITLE"                 ""
   set_ "BN_TITLE_COLOR"           "46"       # ส้ม
   set_ "BN_TITLE_STYLE"           "b"         # bold

   set_ "BN_BORDER_CHAR"           "▬"         # ม่วง/น้ำเงิน
   set_ "BN_BORDER_COLOR"          "125"        # ม่วง/น้ำเงิน
   set_ "BN_BORDER_STYLE"          "b"         # bold
   set_ "BN_BORDER_LEN"            ""          # ความกว้าง border

   set_ "BN_LABEL_COLOR"           "250"       # เทาสว่าง
   set_ "BN_LABEL_STYLE"           "d"         # dim
   set_ "BN_VAL_COLOR"             "202"       # 202
   set_ "BN_VAL_STYLE"             ""
   set_ "BN_SEP"                   " : "
}