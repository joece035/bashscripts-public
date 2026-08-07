#!/bin/bash
# ============================================================
# help.sh — The Ultimate Help Utility
# ============================================================
opstats_data(){
    em1="${EMOJI:-📌}"
    spl1="[Current Profile]"
    spr1="${PROFILE_NAME:-default}"
    
    em2="🏠"
    spl2="[State Directory]"
    spr2_1="${OPENCLAW_STATE_DIR:-}"
    spr2_2="$(basename "${spr2_1}" 2>/dev/null)"
    spr2="$(printf "~/%s\n" "$spr2_2")"
    
    em3="🦞"
    spl3="[Gateway Token]"
    spr3="${OPENCLAW_GATEWAY_TOKEN:--}"
  
    em4="🔌"
    spl4="[GATEWAY PORT]"
    spr4="${OPENCLAW_GATEWAY_PORT:--}"   
}

opstatus2(){
  _style_default 
  
    opstats_data
  
    render_() {
    local ROWS=(
        "🔵|$spl1|$spr1|$em1"
        "🟢|$spl2|$spr2|$em2"
        "🟡|$spl3|$spr3|$em3"
        "🔴|$spl4|$spr4|$em4"
        "🦞|Openclaw ver.|${OPENCLAW_VERSION:--}|🦀"
        
      )
    dashboard_array "${ROWS[@]}"

    }



render_
} #-- ใช้ blockสำเร็จรูปที่ทไว้


jenv(){
   
   local ROWS=(

    
        "|[OPENCLAW_TOKEN]|${OPENCLAW_TOKEN:--}|"
        "|[BRAVE_API_KEY]|$BRAVE_API_KEY|"
        "|[TELEGRAM_BOT_TOKEN]|$TELEGRAM_BOT_TOKEN|"
        "|[OPENCODE_API_KEY]|$OPENCODE_ZEN_API_KEY|"
        "|[OPENCODE_GO_API_KEY]|$OPENCODE_GO_API_KEY|"
        "|[OPENCLAW_STATE_DIR]|$OPENCLAW_STATE_DIR|"
        "|[MODEL]|$MODEL|"
        "|[USDT_BEP20_BITKUB]|$USDT_BEP20_BITKUB|"
        "|[SOL_BITKUB]|$SOL_BITKUB|"
        "|[SOL_METAMAS]|$SOL_METAMAS|"
        "|[BTC_BITKUB]|$BTC_BITKUB|"
        
    )
    dashboard_array "${ROWS[@]}"
}

