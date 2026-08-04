#!/bin/bash  
# ============================================================  
# 01-exercise_block_style.sh - Terminal Layout JOE_style_def
# ============================================================  
# Separation of Concerns: colors + presets merged here
# This file handles: colors, presets, symbols, layout constants, and style presets
# ============================================================

_BLK_STYLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f set_ &>/dev/null; then
    set_() {
        printf -v "$1" "%s" "$2"
    }
fi

# ============================================================
# COLOR PRESETS (merged from 00-exercise_color_config.sh)
# ============================================================
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
    set_ MID_LINE_C        "${MID_LINE_C:-199 \"\"}"
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

symbols_() { 
    local type=""
    type+=$'\n'"∥  ‖  ⟬  ⟭  ⟦  ⟧  |  ¦  ‖  !"$'\n'
    type+="‼  İ  ɭ  l  Ţ  ⌈  ⌉  ⌊  ⌋  —"$'\n'
    type+=$'\n'"↿  ↾  ⇣  ⇡  ⇩  ⇧  ⇦  ⇨  ⇫  ⇮"$'\n'
    type+="⇬  ⇯  ↖  ↗  ↙  ↘  ←  →  ↑  ↓"$'\n'
    type+=$'\n'"▢  ▥  ▨  ▬  ▭  ▣  ▦  ▩  ▮  ▯"$'\n'
    type+="▤  ▧  ◊  ▪  ▫  ▴  ▵  ◂  ▸  ◃"$'\n'
    type+="▹  ◆  ◇  ◈  ▱  ▰  ∎"$'\n'
    type+=$'\n'"◌  ●  ◙  ▼  ▽  ○  ◓  ◍  ◚  ◪"$'\n'
    type+="•  ⁕  ‣  ⁴  ∏  ∐"$'\n'

    printf '%b\n' "$type"
}

new_symbol() {
    cat <<'SYMB'
──────────────
━━━━━━━━━━━━━━
┄┄┄┄┄┄┄┄┄┄┄┄
┈┈┈┈┈┈┈┈┈┈┈┈
══════════════
┌──────────┐
│          │
└──────────┘
╭──────────╮
│          │
╰──────────╯
╔══════════╗
║          ║
╚══════════╝
░░░░░░░░
▒▒▒▒▒▒▒▒
▓▓▓▓▓▓▓▓
████████
← ↑ → ↓
◀ ▲ ▶ ▼
➜ ➝ ➞ ➤
⇒ ⇨ ⇢● ○ ◉ ◎
◍ ◌
⬤ ◯
🟢 🟡 🔴
◢ ◣ ◤ ◥
▲ ▼ ▶ ◀
△ ▽ ▷ ◁
 ▏ ▎ ▍ ▌ ▋ ▊ ▉ █
█ ▉ ▊ ▋ ▌ ▍ ▎ ▏
SYMB
}

# ============================================================
# _default_ - Default style
# ============================================================
_default_() {
    local random_pick="no"
    local color_modes_b=("no" "random" "yes")  
    set_ _data_ROWS        "${_data_ROWS:-}"

    if [[ "$random_pick" = "yes" ]]; then
        set_ BORDER_RANDOM_C    "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ FRAME_RANDOM_C     "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ MID_RANDOM_C       "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
    else
        set_ BORDER_RANDOM_C   "true"
        set_ FRAME_RANDOM_C    "no"
        set_ MID_RANDOM_C      "no"
    fi 
    
    set_ OFFSET             "1"
    set_ BORDER_RANDOM      "▨"
    set_ FRAME_RANDOM       "‖"
    set_ MID_LINE           "┄"
    set_ ROW_FRAME_L        "‖"
    set_ ROW_FRAME_R        "‖"
    set_ MID_FRAME_L        "‖"
    set_ MID_FRAME_R        "‖"
    set_ TOP_BORDER         "━"
    set_ BOT_BORDER         "━"
    set_ MD_SEP_            " : "

    _apply_color_preset "default"
}

# ============================================================
# _a_ - Style A (JOE_ENV status)
# ============================================================
_a_() {
    local random_pick="yes"
    local color_modes_b=("no" "random" "yes")
    set_ _data_ROWS        "exercise_op_profile"

    if [[ "$random_pick" = "yes" ]]; then
        set_ BORDER_RANDOM_C    "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ FRAME_RANDOM_C     "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ MID_RANDOM_C       "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
    else
        set_ BORDER_RANDOM_C   "yes"
        set_ FRAME_RANDOM_C    "no"
        set_ MID_RANDOM_C      "no"
    fi 
    
    set_ OFFSET            "1"
    set_ BORDER_RANDOM      "◙"
    set_ FRAME_RANDOM       "‖"
    set_ MID_LINE           '-'
    set_ ROW_FRAME_L        "⟬"
    set_ ROW_FRAME_R        "⟭"
    set_ MID_FRAME_L        "⟭"
    set_ MID_FRAME_R        "⟬"
    set_ TOP_BORDER         "◙"
    set_ BOT_BORDER         "◙"

    _apply_color_preset "a"
}

# ============================================================
# _b_ - Style B
# ============================================================
_b_() {
    local random_pick="no"
    local color_modes_b=("no" "random" "yes")  
    set_ _data_ROWS        ""

    if [[ "$random_pick" = "yes" ]]; then
        set_ BORDER_RANDOM_C    "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ FRAME_RANDOM_C     "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ MID_RANDOM_C       "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
    else
        set_ BORDER_RANDOM_C   "yes"
        set_ FRAME_RANDOM_C    "no"
        set_ MID_RANDOM_C      "no"
    fi 
    
    set_ OFFSET            "0"
    set_ BORDER_RANDOM      "▨"
    set_ FRAME_RANDOM       "‖"
    set_ MID_LINE           "▰"
    set_ ROW_FRAME_L        "|"
    set_ ROW_FRAME_R        "|"
    set_ MID_FRAME_L        "|"
    set_ MID_FRAME_R        "|"
    set_ TOP_BORDER         "▰"
    set_ BOT_BORDER         "▰"
    set_ MD_SEP_            ' : '

    _apply_color_preset "b"
}

# ============================================================
# _c_ - Style C (JENV)
# ============================================================
_c_() {
    local random_pick="no"
    local color_modes_b=("no" "random" "yes")  
    set_ _data_ROWS        "exercise_jenv"

    if [[ "$random_pick" = "yes" ]]; then
        set_ BORDER_RANDOM_C    "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ FRAME_RANDOM_C     "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
        set_ MID_RANDOM_C       "${color_modes_b[$(( RANDOM % ${#color_modes_b[@]} ))]}"
    else
        set_ BORDER_RANDOM_C   "yes"
        set_ FRAME_RANDOM_C    "no"
        set_ MID_RANDOM_C      "no"
    fi 
    
    set_ OFFSET            "-0.5"
    set_ BORDER_RANDOM      "▨"
    set_ FRAME_RANDOM       "‖"
    set_ MID_LINE           "▱"
    set_ ROW_FRAME_L        "⟬"
    set_ ROW_FRAME_R        "⟭"
    set_ MID_FRAME_L        "⟬"
    set_ MID_FRAME_R        "⟭"
    set_ TOP_BORDER         "▰"
    set_ BOT_BORDER         "▰"
    set_ MD_SEP_            " : "

    _apply_color_preset "c"
}

# ============================================================
# _random_ - Random style generator
# ============================================================
_random_() {
    set_ OFFSET            "0"
   
    local H_LINE=("─" "━" "▬" "▭" "▱" "═" "–")
    local H_BLOCK=("─" "━" "▬" "▭" "▱" "▰" "▨" "–" "-")
    local DOT=("◌" "◙" "◓" "◍" "◚" "◪" "•" "⁕" "‣" "∐")
    local ROW_FRAMES=("| |" "¦ ¦" "‖ ‖" "║ ║" "∣ ∣" "⟨ ⟩" "⟬ ⟭" "⟦ ⟧" "⌈ ⌉" "⌊ ⌋")

    local pick_h1="${H_LINE[$(( RANDOM % ${#H_LINE[@]} ))]}"
    local pick_h2="${H_BLOCK[$(( RANDOM % ${#H_BLOCK[@]} ))]}"
    
    local pick_rf="${ROW_FRAMES[$(( RANDOM % ${#ROW_FRAMES[@]} ))]}"
    local pick_vL="${pick_rf% *}"
    local pick_vR="${pick_rf#* }"
    
    local pick_mL="$pick_vL"
    local pick_mR="$pick_vR"
    if [[ "$pick_vL" == "⟨" ]]; then pick_mL="⟩"; pick_mR="⟨"; fi
    if [[ "$pick_vL" == "⟬" ]]; then pick_mL="⟭"; pick_mR="⟬"; fi
    if [[ "$pick_vL" == "⟦" ]]; then pick_mL="⟧"; pick_mR="⟦"; fi
    if [[ "$pick_vL" == "⌈" ]]; then pick_mL="⌉"; pick_mR="⌈"; fi
    if [[ "$pick_vL" == "⌊" ]]; then pick_mL="⌋"; pick_mR="⌊"; fi
    
    local pick_dot="${DOT[$(( RANDOM % ${#DOT[@]} ))]}"

    set_ TOP_BORDER         "$pick_h1"
    set_ BOT_BORDER         "$pick_h1"
    set_ MID_LINE           "$pick_h2"
    set_ ROW_FRAME_L        "$pick_vL"
    set_ ROW_FRAME_R        "$pick_vR"
    set_ MID_FRAME_L        "$pick_mL"
    set_ MID_FRAME_R        "$pick_mR"
    set_ MD_SEP_            " : "

    local color_modes=("yes" "no" "random")
    local frame_modes=("no" "random")
    set_ BORDER_RANDOM_C    "${color_modes[$(( RANDOM % ${#color_modes[@]} ))]}"
    set_ FRAME_RANDOM_C     "${frame_modes[$(( RANDOM % ${#frame_modes[@]} ))]}"
    set_ MID_RANDOM_C       "${frame_modes[$(( RANDOM % ${#frame_modes[@]} ))]}"
    set_ BORDER_RANDOM      "$pick_dot"
    set_ FRAME_RANDOM       "$pick_vL"

    _apply_color_preset "rainbow"
}
