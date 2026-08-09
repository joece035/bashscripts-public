#!/bin/bash  
# ============================================================  
# 01-exercise_joe.sh - JOE Environment Dashboard Engine
# ============================================================  
# Demonstrates usage of block_engine.sh with JOE_ENV integration  
#  
# Public API:  
#   n [style|status] [offset]
#   exercise_dashboard <<EOF  
#   EMOJI_L|LABEL|value|EMOJI_R  
#   EOF  
#  
#   generate_status | exercise_dashboard  
#   exercise_dashboard_array "${exercise_rows[@]}"  
# ============================================================

# Auto-source dependent modules relative to this script
_EX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_BS_ROOT="$(cd "${_EX_DIR}/../.." && pwd)"

[[ -f "${_BS_ROOT}/core/01-colors.sh" ]] && source "${_BS_ROOT}/core/01-colors.sh"
[[ -f "${_BS_ROOT}/functions/00.1-function-tools.sh" ]] && source "${_BS_ROOT}/functions/00.1-function-tools.sh"
[[ -f "${_EX_DIR}/02-exercise_block_style.sh" ]] && source "${_EX_DIR}/02-exercise_block_style.sh"
[[ -f "${_EX_DIR}/03-exercise _status.sh" ]] && source "${_EX_DIR}/03-exercise _status.sh"



# Fallback set_ helper
if ! declare -f set_ &>/dev/null; then
    set_() { printf -v "$1" "%s" "$2"; }
fi

# Fallback color applicator
_apply_color_to() {

    local config="${1:-gr}"
    local text="$2"
    local clr sty
    clr="${config%% *}"  # -- extract color '%% *'= ตัดเอาก่อน space แรก
    sty="${config#* }"  # -- extract style  '#* '= ตัดเอาหลังจาก space แรก   
    [[ "$sty" == "$clr" ]] && sty='' # -- ถ้าไม่มีสไตล์ให้แสดงสีเท่านั้น
    if declare -f color &>/dev/null; then # -- ถ้า color function มีอยู่แล้ว
        color "$clr" "$sty" "$text"
    else
        printf "%s" "$text"
    fi
}
_apply_random_color_to() {

    local config="${1:-b}"  # -- format "$style"
    local text="$2"
    local rc_sty
    rc_sty="${config}"  # -- extract style  
    if declare -f rc &>/dev/null; then # -- ถ้า rc function มีอยู่แล้ว
        rc "$rc_sty" "$text"
    else
        printf "%s" "$text"
    fi
}
# ============================================================
# LAYER 1 - Public Entry Point
# ============================================================
n() {
    local target="${1:-a}"
    export theme=""
    shift 2>/dev/null || true
   
    case "$target" in 
        s|status|a)
            set_ theme "_a_"
            ;;
        oc|b) 
            set_ theme "_b_"
            ;;
        jenv|c)
            set_ theme "_c_"
            ;;
        r|random)
            set_ theme "_random_"
            ;;
        *)
            set_ theme "_default_"
            ;;
    esac
    $theme
    case "$target" in
        s|status_new|a|r|random|*)
            exercise_status "$@"
            ;;
        oc|b)
            exercise_oc "$@"
            ;;
        jenv|c)
            exercise_jenv "$@"
            ;;
    esac
}

# Default Layout Constants
eml_w="${EML_W:-4}"           # cells for left emoji column  
emr_w="${EMR_W:-5}"           # cells for right emoji column  
emj_v_gap="${EMJ_V_GAP:-2}"   # spaces after value before right icon  
pad_inner="${PAD_INNER:-2}"   # inner horizontal padding  
MD_SEP_="${MD_SEP_:-" : "}"   # label-value separator  

# ============================================================  
# LAYER 2 - Icon Engine (emoji visual width per JOE_ENV)  
# ============================================================  
_icon_w() {  
    case "${JOE_ENV:-}" in  
        GIT-BASH) echo 2 ;;  
        *)        echo 2 ;;  
    esac  
}  
  
# ============================================================  
# LAYER 3 - repeat_char utility  
# ============================================================  
_repeat_char() {  
    local char="$1"
    local count="${2:-0}"
    (( count <= 0 )) && return 0
    printf "%*s" "$count" "" | sed "s/ /$char/g"  
}  
  
# ============================================================  
# LAYER 4 - Layout Scanner  
#   Scans exercise_rows -> finds max label and max value lengths  
#   Sets globals: _max_label  _max_value  
# ============================================================  
_scan_width() {  
    local exercise_rows=("$@")  
    _max_label=0  
    _max_value=0  
    local row eml label value emr
    eml="$(ew eml)" emr="$(ew emr)"  
    for row in "${exercise_rows[@]}"; do  
        IFS=' ' read -r eml label value emr <<< "$row"  
        ($(ew label) > _max_label ) && _max_label=$(ew label)  
        (( $(ew value) > _max_value )) && _max_value=$(ew value)  
    done  
}  
  
# ============================================================  
# LAYER 5 - Width Calculator  
#   Computes _width_ from constants + scan result
# ============================================================  
_width_cal() {
    local sep_len=${#MD_SEP_} max_w min_w term_cols w
    w="${_width_}"

    term_cols=$(tput cols)
    (( term_cols <= 0 )) && term_cols=80
    
    max_w=$(( term_cols - 2 ))
    min_w=$(( eml_w + _max_label + sep_len + _max_value + emj_v_gap + emr_w + pad_inner ))

    if [[ -z "$w" ]]; then
        w=$min_w
    fi

    if (( w >= max_w )); then
       w=$max_w
    elif (( w < min_w )); then
       w=$min_w
    fi
    _width_=$w
    export _width_
}
# ============================================================  
# LAYER 6 - Border Generator  
#   Sets globals: _TOP_BORDER  _BOT_BORDER  _BLK_MID_INNER  
# ============================================================  
_gen_border() {  
    local top_c="${TOP_BORDER:-━}"
    local bot_c="${BOT_BORDER:-━}"
    local random_symbol="${BORDER_RANDOM:-━}"
    local mid_c="${MID_LINE:-┄}"

    _TOP_BORDER="$(_repeat_char "${top_c}" "$_width_")"  
    _BOT_BORDER="$(_repeat_char "${bot_c}" "$_width_")"
    _RANDOM_BORDER="$(_repeat_char "${random_symbol}" "$_width_")" 

    if [[ "${BORDER_RANDOM_C}" == "yes" || "${BORDER_RANDOM_C}" == "true" ]]; then
        _TOP_BORDER_FINAL="$(_apply_random_color_to "b" "${_RANDOM_BORDER}")"
        _BOT_BORDER_FINAL="$(_apply_random_color_to "b" "${_RANDOM_BORDER}")"
    else
        _TOP_BORDER_FINAL="$(_apply_color_to "${TOP_BORDER_C:-lb b}" "${_TOP_BORDER}")"
        _BOT_BORDER_FINAL="$(_apply_color_to "${BOT_BORDER_C:-lb b}" "${_BOT_BORDER}")"
    fi

    local inner_length=$(( _width_ - 2 ))
    (( inner_length < 0 )) && inner_length=$((_width_-2))
    
    local _mid_bar="$(_repeat_char "${mid_c}" "$inner_length")"
    if declare -f _apply_color_to &>/dev/null; then
        _BLK_MID_INNER="$(_apply_color_to "${MID_LINE_C:-gr \"\"}" "$_mid_bar")"
    else
        _BLK_MID_INNER="$_mid_bar"
    fi
}  
  
# ============================================================  
# LAYER 7 - Center Calculator  
#   Centers block in terminal. Sets global: _BLK_SP  
# ============================================================  
_center_cal() {
    local _term_w max_indt min_indt=0 _indt
    local off="${OFFSET:-0}"   # พิกัดฉาก: -1 (ซ้ายสุด), 0 (ตรงกลาง), 1 (ขวาสุด)
    
    _term_w=$(tput cols)

    # ระยะขอบว่างรวมที่เหลือ (Available space) และระยะครึ่งหนึ่ง (Mid margin)
    local avail_space=$(( _term_w - _width_ ))
    (( avail_space < 0 )) && avail_space=0
    
    max_indt=$avail_space
    local mid_margin=$(( avail_space / 2 ))

    # สูตรพิกัด: Indent = mid_margin + (OFFSET * mid_margin)
    #   - OFFSET = -1 -> mid_margin - mid_margin = 0 (ชิดซ้าย)
    #   - OFFSET =  0 -> mid_margin + 0          = mid_margin (ตรงกลาง)
    #   - OFFSET =  1 -> mid_margin + mid_margin = max_indt (ชิดขวา)
    local _indt_raw
    _indt_raw=$(bc_ n "${mid_margin} + (${off} * ${mid_margin})")
    _indt=$(LC_ALL=C printf "%.0f" "${_indt_raw:-0}")

    # Clamping Boundary (คุมไม่ให้ออกนอกขอบจอ)
    (( _indt < min_indt )) && _indt=$min_indt
    (( _indt > max_indt )) && _indt=$max_indt

    printf -v _BLK_SP "%*s" "${_indt}" ""
    export _BLK_SP 
}

# ============================================================  
# LAYER 8 - Row Renderer  
#   Args: eml label value emr  
# ============================================================  
_render_row() {  
    local eml="$1" label="$2" value="$3" emr="$4"  
    local icon_w; icon_w=$(_icon_w)  
  
    local left_pad=$(( (eml_w - icon_w) / 2 ))  
    local left_rem=$(( eml_w - icon_w - left_pad ))  
    local label_pad=$(( _max_label - ${#label} ))  
    local value_pad=$(( _max_value - ${#value} + emj_v_gap ))  
    local r_left=$(( (emr_w - icon_w) / 2 ))  
    local r_right=$(( emr_w - icon_w - r_left ))  
  
    (( left_pad < 0 )) && left_pad=0
    (( left_rem < 0 )) && left_rem=0
    (( label_pad < 0 )) && label_pad=0
    (( value_pad < 0 )) && value_pad=0
    (( r_left < 0 )) && r_left=0
    (( r_right < 0 )) && r_right=0

    local lbl_str val_str
    lbl_str="$(_apply_color_to "${LABEL_C:-gr \"\"}" "$label")"
    val_str="$(_apply_color_to "${VALUE_C:-w bi}" "$value")"

    printf "%*s%s%*s%s%*s%s%s%*s%*s%s%*s" \
        "$left_pad" "" "$eml" "$left_rem" "" "$lbl_str" "$label_pad" "" "$MD_SEP_" "$val_str" "$value_pad" "" "$r_left" "" "$emr" "$r_right" ""
}  
  
# ============================================================  
# LAYER 9 - Frame Engine  
# ============================================================  
_gen_frame() {
    _blk_frame() {  
        local rf_l="$(_apply_color_to "${ROW_FRAME_C:-gr \"\"}" "${ROW_FRAME_L:-|}")"
        local rf_r="$(_apply_color_to "${ROW_FRAME_C:-gr \"\"}" "${ROW_FRAME_R:-|}")"
        printf "%s%s%s%s\n" "$_BLK_SP" "$rf_l" "$1" "$rf_r"  
    }  
    _blk_frame_mid() {  
        local mf_l="$(_apply_color_to "${MID_FRAME_C:-gr \"\"}" "${MID_FRAME_L:-|}")"
        local mf_r="$(_apply_color_to "${MID_FRAME_C:-gr \"\"}" "${MID_FRAME_R:-|}")"
        printf "%s%s%b%s\n" "$_BLK_SP" "$mf_l" "$_BLK_MID_INNER" "$mf_r"
    }  
}

# ============================================================  
# LAYER 10 - exercise_dashboard Renderer (PUBLIC API)  
# ============================================================  
exercise_dashboard() {  
    local exercise_rows=()  
    local line  
    while IFS= read -r line; do  
        [[ -z "$line" ]] && continue  
        exercise_rows+=("$line")  
    done  
    [[ ${#exercise_rows[@]} -eq 0 ]] && return 0  

    _scan_width "${exercise_rows[@]}"  
    _width_cal  
    _gen_border  
    _center_cal 
    _gen_frame 
  
    # Top border  
    printf "%s%s\n" "$_BLK_SP" "$_TOP_BORDER_FINAL" 
  
    # Rows  
    local i=0 eml label value emr row_str  
    for row in "${exercise_rows[@]}"; do  
        IFS='|' read -r eml label value emr <<< "$row"  
        row_str="$(_render_row "$eml" "$label" "$value" "$emr")"  
        _blk_frame "$row_str"  
        if (( i < ${#exercise_rows[@]} - 1 )); then  
            _blk_frame_mid  
        fi  
        (( i++ ))  
    done  
  
    # Bottom border  
    printf "%s%s\n" "$_BLK_SP" "$_BOT_BORDER_FINAL" 
}  

# CONVENIENCE - exercise_dashboard_array (pass rows as arguments)  
exercise_dashboard_array() {  
    printf '%s\n' "$@" | exercise_dashboard  
}

