#!/bin/bash
# ============================================================
# 00-exercise_color_config.sh — Color Presets (SSOT)
# ============================================================
# Separation of Concerns: สีแยกออกจาก layout/symbols
#
# แต่ละ preset คือ function ที่ set_ 7 color variables:
#   MID_LINE_C, ROW_FRAME_C, MID_FRAME_C,
#   TOP_BORDER_C, BOT_BORDER_C,
#   LABEL_C, VALUE_C
#
# Format: '<color> <style>'
#   color = ชื่อสี (r/g/y/c/b/m/w/gr/lr/lg/lcr/lb/lm/ora) หรือ 256 code
#   style = b=bold d=dim i=italic u=underline (ผสมได้ เช่น "bi")
# ============================================================

# Fallback set_ helper if not already defined
if ! declare -f set_ &>/dev/null; then
    set_() {
        printf -v "$1" "%s" "$2"
    }
fi

# ----------------------------------------------------------
# Helper: แปลง preset name → set_ color variables
# ----------------------------------------------------------
_apply_color_preset() {
    local preset="${1:-default}"
    case "$preset" in
        default)  _color_preset_default ;;
        a)        _color_preset_a ;;
        b)        _color_preset_b ;;
        c)        _color_preset_c ;;
        d)        _color_preset_d ;;
        rainbow)  _color_preset_rainbow ;;
        *)        _color_preset_default ;;
    esac
}

# ----------------------------------------------------------
# Preset: default — ธีมเทา/ฟ้า คลาสสิก
# ----------------------------------------------------------
_color_preset_default() {
    set_ MID_LINE_C        "${MID_LINE_C:-gr \"\"}"
    set_ ROW_FRAME_C       "${ROW_FRAME_C:-gr \"\"}"
    set_ MID_FRAME_C       "${MID_FRAME_C:-gr \"\"}"
    set_ TOP_BORDER_C      "${TOP_BORDER_C:-lb b}"
    set_ BOT_BORDER_C      "${BOT_BORDER_C:-lb b}"
    set_ LABEL_C           "${LABEL_C:-237 bi}"
    set_ VALUE_C           "${VALUE_C:-199 bi}"
}

# ----------------------------------------------------------
# Preset: a — ธีมเขียว/ฟ้าอ่อน (rainbow-friendly)
# ----------------------------------------------------------
_color_preset_a() {
    set_ MID_LINE_C        "${MID_LINE_C:-cn 10 \"\"}"
    set_ ROW_FRAME_C       "${ROW_FRAME_C:-gr \"\"}"
    set_ MID_FRAME_C       "${MID_FRAME_C:-gr \"\"}"
    set_ TOP_BORDER_C      "${TOP_BORDER_C:-lg b}"
    set_ BOT_BORDER_C      "${BOT_BORDER_C:-lg b}"
    set_ LABEL_C           "${LABEL_C:-gr \"\"}"
    set_ VALUE_C           "${VALUE_C:-lcr bi}"
}

# ----------------------------------------------------------
# Preset: b — ธีมฟ้าเข้ม/ขอบสีน้ำเงิน
# ----------------------------------------------------------
_color_preset_b() {
    set_ MID_LINE_C        "${199:-240 \"\"}"
    set_ ROW_FRAME_C       "${ROW_FRAME_C:-240 \"\"}"
    set_ MID_FRAME_C       "${MID_FRAME_C:-240 \"\"}"
    set_ TOP_BORDER_C      "${TOP_BORDER_C:-lb b}"
    set_ BOT_BORDER_C      "${BOT_BORDER_C:-lb b}"
    set_ LABEL_C           "${LABEL_C:-248 bi}"
    set_ VALUE_C           "${VALUE_C:-lcr bi}"
}

# ----------------------------------------------------------
# Preset: c — ธีมเขียว/ส้ม สดใส
# ----------------------------------------------------------
_color_preset_c() {
    set_ MID_LINE_C        "${MID_LINE_C:-gr \"\"}"
    set_ ROW_FRAME_C       "${ROW_FRAME_C:-gr \"\"}"
    set_ MID_FRAME_C       "${MID_FRAME_C:-gr \"\"}"
    set_ TOP_BORDER_C      "${TOP_BORDER_C:-gr b}"
    set_ BOT_BORDER_C      "${BOT_BORDER_C:-gr b}"
    set_ LABEL_C           "${LABEL_C:-lg \"\"}"
    set_ VALUE_C           "${VALUE_C:-ora bi}"
}

# ----------------------------------------------------------
# Preset: d — ธีมฟ้า/ขาว ขอบฟ้า
# ----------------------------------------------------------
_color_preset_d() {
    set_ MID_LINE_C        "${MID_LINE_C:-237 \"\"}"
    set_ ROW_FRAME_C       "${ROW_FRAME_C:-237 \"\"}"
    set_ MID_FRAME_C       "${MID_FRAME_C:-237 \"\"}"
    set_ TOP_BORDER_C      "${TOP_BORDER_C:-lb b}"
    set_ BOT_BORDER_C      "${BOT_BORDER_C:-lb b}"
    set_ LABEL_C           "${LABEL_C:-gr \"\"}"
    set_ VALUE_C           "${VALUE_C:-w \"\"}"
}

# ----------------------------------------------------------
# Preset: rainbow — สุ่มสี (runtime random)
# ----------------------------------------------------------
_color_preset_rainbow() {
    local colors=("gr" "lg" "w" "lc" "lb" "lm")
    local styles_b=("b" "bi" "bl" "bd" "")
    local styles_l=("" "b" "bi" "bl")

    local c_mid="${colors[$(( RANDOM % ${#colors[@]} ))]}"
    local c_frame="${colors[$(( RANDOM % ${#colors[@]} ))]}"
    local c_border="${colors[$(( RANDOM % ${#colors[@]} ))]}"
    local style_b="${styles_b[$(( RANDOM % ${#styles_b[@]} ))]}"
    local style_l="${styles_l[$(( RANDOM % ${#styles_l[@]} ))]}"

    set_ MID_LINE_C        "${c_mid} ''"
    set_ ROW_FRAME_C       "${c_frame} ''"
    set_ MID_FRAME_C       "${c_frame} ''"
    set_ TOP_BORDER_C      "${c_border} ${style_b:-''}"
    set_ BOT_BORDER_C      "${c_border} ${style_b:-''}"
    set_ LABEL_C           "${colors[$(( RANDOM % ${#colors[@]} ))]} ${style_l:-''}"
    set_ VALUE_C           "w ${style_b:-''}"
}
