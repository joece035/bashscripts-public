#!/bin/bash
# ============================================================
# grid-engine/entry.sh — Grid Engine Public API
# ============================================================
# Flexible N-column grid renderer.
# Self-contained — no dependency on JOE Block Engine.
#
# Pipeline: Col Defs → Scan → Layout → Theme → Render → Output
#
# Modules (from lib/):
#   str.sh    — _str_width, _str_repeat_pattern, _str_truncate
#   color.sh  — _c_apply (loads 01-colors.sh via SSOT)
#   cols.sh   — col_add, col_reset, g_scan, g_build
#   render.sh — render_row, render_header, render_border_*
#   theme.sh  — load_theme, _style_grid_*
# ============================================================

# -- Resolve this script's directory
_GRID_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${funcsourcetrace[1]%%:*}}")" && pwd)"

# -- Source all lib modules
source "${_GRID_DIR}/lib/str.sh"
source "${_GRID_DIR}/lib/color.sh"
source "${_GRID_DIR}/lib/cols.sh"
source "${_GRID_DIR}/lib/theme.sh"
source "${_GRID_DIR}/lib/render.sh"

# ============================================================
# grid — PUBLIC API (main entry point)
#   Usage:
#     grid [style] [offset]
#     grid                    — default grid style
#     grid compact            — compact (no frame)
#     grid fancy              — fancy (box drawing)
#     grid minimal            — minimal (no borders)
#     grid rainbow            — rainbow borders
#     grid fancy -0.25        — fancy + offset right
#
#   Before calling, set columns:
#     col_add "NAME" "l" 15 0 ""
#     col_add "CPU"  "r" 6  0 "203 bi"
#     grid
# ============================================================
grid() {
    local arg1="${1:-}" arg2="${2:-}"
    local style="grid" offset=""

    if [[ "$arg1" =~ ^-?[0-9]+$ ]]; then
        offset="$arg1"
    else
        [[ -n "$arg1" ]] && style="$arg1"
        [[ "$arg2" =~ ^-?[0-9]+$ ]] && offset="$arg2"
    fi

    load_theme "$style" "$offset"

    # Dispatch to provider (set by grid_set_provider or default)
    local provider="${_GRID_PROVIDER:-grid_default_provider}"
    if declare -f "$provider" >/dev/null 2>&1; then
        "$provider"
    else
        echo "grid: provider '$provider' not found. Use grid_set_provider or grid_table."
        return 1
    fi
}

# ============================================================
# grid_set_provider — Set the data provider function
# ============================================================
grid_set_provider() {
    _GRID_PROVIDER="$1"
}

# ============================================================
# grid_default_provider — Reads stdin, renders grid
# ============================================================
grid_default_provider() {
    local ROWS=()
    local line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        ROWS+=("$line")
    done
    [[ ${#ROWS[@]} -eq 0 ]] && return 0

    local ncol="${_COL[count]:-0}"
    (( ncol == 0 )) && { echo "grid: no columns defined"; return 1; }

    # -- Scan
    g_scan "${ROWS[@]}"
    g_build "${_THEME[offset]:-0}"
    (( ${_LAY[bw]:-0} == 0 )) && return 0

    # -- Render
    render_border_top

    if (( ${_LAY[has_header]:-0} == 1 )); then
        render_header
        render_mid
    fi

    local i=0 n=${#ROWS[@]}
    for row in "${ROWS[@]}"; do
        [[ "$row" == "::*" ]] && continue
        render_row "$row"
        if (( i < n - 1 )); then
            local ni=$(( i + 1 ))
            (( ni < n )) && [[ "${ROWS[$ni]}" != "::*" ]] && render_mid
        fi
        (( i++ ))
    done

    render_border_bot
}

# ============================================================
# grid_table — Quick table from arguments
#   Usage:
#     grid_table \
#       "col_def|col_def|..." \
#       "row_val|row_val|..." ...
#
#   Column def: name:align:min_w:max_w:color
#   Row val:    val1|val2|...
#
#   Example:
#     grid_table \
#       "NAME:l:10:0:" \
#       "CPU:r:6:0:203 bi" \
#       "MEM:r:6:0:118 bi" \
#       -- \
#       "bash|2.5|5.1" \
#       "python|15.3|12.0"
# ============================================================
grid_table() {
    col_reset

    local args=("$@")
    local sep_idx=-1 i

    # Find "--" separator
    for (( i=0; i<${#args[@]}; i++ )); do
        [[ "${args[$i]}" == "--" ]] && { sep_idx=$i; break; }
    done

    if (( sep_idx == -1 )); then
        # No "--": first arg is pipe-separated col defs
        if [[ -n "${args[0]:-}" ]]; then
            _split_on _gt_cols "${args[0]}"
            local ci=0
            for cdef in "${_gt_cols[@]}"; do
                IFS=':' read -r cn ca cmn cmx ccl <<< "$cdef"
                col_add "${cn:-c${ci}}" "${ca:-l}" "${cmn:-0}" "${cmx:-0}" "${ccl:-}"
                (( ci++ ))
            done
        fi
        shift 1
        local -a _gt_rows=("$@")
    else
        # Parse col defs before "--"
        local ci=0
        for (( i=0; i<sep_idx; i++ )); do
            IFS=':' read -r cn ca cmn cmx ccl <<< "${args[$i]}"
            col_add "${cn:-c${ci}}" "${ca:-l}" "${cmn:-0}" "${cmx:-0}" "${ccl:-}"
            (( ci++ ))
        done
        local -a _gt_rows=("${args[@]:$((sep_idx+1))}")
    fi

    # -- Set default theme if not set
    [[ -z "${_THEME[bc]:-}" ]] && load_theme "grid"

    # -- Render
    printf '%s\n' "${_gt_rows[@]}" | grid_default_provider
}

# ============================================================
# grid_random — Random style selector
# ============================================================
grid_random() {
    local mode="${1:-pure}"
    local styles=("grid" "grid_compact" "grid_fancy" "grid_minimal" "grid_rainbow")

    case "$mode" in
        s|shuffle)
            if [[ -z "${_GRD_DECK[*]:-}" ]] || (( ${#_GRD_DECK[@]} == 0 )); then
                _GRD_DECK=("${styles[@]}")
                local i j tmp
                for (( i=${#_GRD_DECK[@]}-1; i>0; i-- )); do
                    j=$(( RANDOM % (i+1) ))
                    tmp="${_GRD_DECK[$i]}"
                    _GRD_DECK[$i]="${_GRD_DECK[$j]}"
                    _GRD_DECK[$j]="$tmp"
                done
            fi
            local pick="${_GRD_DECK[-1]}"
            unset '_GRD_DECK[-1]'
            load_theme "$pick"
            ;;
        *)
            load_theme "${styles[$(( RANDOM % ${#styles[@]} ))]}"
            ;;
    esac

    local provider="${_GRID_PROVIDER:-grid_default_provider}"
    if declare -f "$provider" >/dev/null 2>&1; then
        "$provider"
    fi
}

# ============================================================
# grid_from — Build grid from parallel arrays
#   Usage:
#     grid_from \
#       --cols "NAME:l:10:0:" "CPU:r:6:0:" \
#       --rows "bash|2.5" "python|15.3" \
#       --style grid_fancy \
#       --offset 0
# ============================================================
grid_from() {
    local -a _gf_cols=() _gf_rows=()
    local _gf_style="grid" _gf_offset="0"

    while (( $# > 0 )); do
        case "$1" in
            --cols)   shift; while (( $# > 0 )) && [[ "$1" != "--"* ]]; do _gf_cols+=("$1"); shift; done ;;
            --rows)   shift; while (( $# > 0 )) && [[ "$1" != "--"* ]]; do _gf_rows+=("$1"); shift; done ;;
            --style)  _gf_style="$2"; shift 2 ;;
            --offset) _gf_offset="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    col_reset
    local ci=0
    for cdef in "${_gf_cols[@]}"; do
        IFS=':' read -r cn ca cmn cmx ccl <<< "$cdef"
        col_add "${cn:-c${ci}}" "${ca:-l}" "${cmn:-0}" "${cmx:-0}" "${ccl:-}"
        (( ci++ ))
    done

    load_theme "$_gf_style" "$_gf_offset"

    if (( ${#_gf_rows[@]} > 0 )); then
        printf '%s\n' "${_gf_rows[@]}" | grid_default_provider
    fi
}
