#!/bin/bash
# ============================================================
# grid-engine/lib/cols.sh — Column Definitions & Layout
# ============================================================
# Define columns, scan rows, compute widths.
#
# Public API:
#   col_reset           — clear all columns
#   col_add <def...>    — add column (auto-index)
#   col_define <i> <def> — set column at index
#   col_count           — return column count
#   col_get <i> <field> — get column field
#   g_scan <rows...>    — scan rows for max widths
#   g_build [offset]    — compute block_w, indent
#
# Column definition fields:
#   name    — display name (header)
#   align   — l (left) | c (center) | r (right)
#   min_w   — minimum width (0 = auto)
#   max_w   — maximum width (0 = unlimited)
#   color   — default color spec for cells
# ============================================================

if [[ -n "${BASH_VERSION:-}" ]]; then
    declare -g -A _COL 2>/dev/null || true
    declare -g -A _LAY 2>/dev/null || true
else
    typeset -g -A _COL 2>/dev/null || true
    typeset -g -A _LAY 2>/dev/null || true
fi

# -- Constants
GRID_PAD=2       # inner horizontal padding (total, split left+right)
GRID_GAP=1       # gap on each side of column separator

# ============================================================
# Column CRUD
# ============================================================

col_reset() {
    local count="${_COL[count]:-0}"
    local i
    for (( i=0; i<count; i++ )); do
        unset "_COL[n_${i}]" "_COL[a_${i}]" "_COL[mn_${i}]" "_COL[mx_${i}]" "_COL[cl_${i}]"
    done
    unset "_COL[count]"
    _COL[count]=0
}

# col_define <index> <name> [align] [min_w] [max_w] [color]
col_define() {
    local idx="$1"
    _COL["n_${idx}"]="${2:-col_${idx}}"
    _COL["a_${idx}"]="${3:-l}"
    _COL["mn_${idx}"]="${4:-0}"
    _COL["mx_${idx}"]="${5:-0}"
    _COL["cl_${idx}"]="${6:-}"
    _COL[count]="$(( idx + 1 ))"
}

# col_add <name> [align] [min_w] [max_w] [color]
col_add() {
    local idx="${_COL[count]:-0}"
    col_define "$idx" "$@"
    _COL[_last]="$idx"
}

col_count() { echo "${_COL[count]:-0}"; }

# col_get <index> <field>
#   field: name, align, min_w, max_w, color
col_get() {
    local idx="$1" field="$2"
    case "$field" in
        name)   echo "${_COL[n_${idx}]:-}" ;;
        align)  echo "${_COL[a_${idx}]:-l}" ;;
        min_w)  echo "${_COL[mn_${idx}]:-0}" ;;
        max_w)  echo "${_COL[mx_${idx}]:-0}" ;;
        color)  echo "${_COL[cl_${idx}]:-}" ;;
    esac
}

# ============================================================
# Cell Parser (inline color override)
# ============================================================
# Input: "color_spec::value" or just "value"
# Sets:  _cell_val, _cell_clr
_grid_parse_cell() {
    local raw="$1"
    if [[ "$raw" == *"::"* ]]; then
        _cell_clr="${raw%%::*}"
        _cell_val="${raw#*::}"
    else
        _cell_clr=""
        _cell_val="$raw"
    fi
}

# ============================================================
# Scan: compute max visual width per column
# ============================================================
# g_scan <row1> <row2> ...
# Writes: _COL[w_${i}] for each column
g_scan() {
    local rows=("$@")
    local ncol="${_COL[count]:-0}"

    # -- Collect values per column
    local c
    for (( c=0; c<ncol; c++ )); do
        eval "_col_vals_${c}=()"
    done

    local row has_header=0
    for row in "${rows[@]}"; do
        [[ -z "$row" ]] && continue
        [[ "$row" == "::*" ]] && { has_header=1; continue; }

        _split_on _g_parts "$row"
        local nf=${#_g_parts[@]}
        for (( c=0; c<ncol && c<nf; c++ )); do
            eval "_col_vals_${c}+=(\"\${_g_parts[$c]}\")"
        done
        for (( c=nf; c<ncol; c++ )); do
            eval "_col_vals_${c}+=(\"\")"
        done
    done

    # -- Compute max width per column
    for (( c=0; c<ncol; c++ )); do
        local max_vw=0 vw

        # Header name
        local hdr="${_COL[n_${c}]:-}"
        if [[ -n "$hdr" ]]; then
            vw="$(_str_width "$hdr")"
            (( vw > max_vw )) && max_vw=$vw
        fi

        # Data values
        eval "local -a _cv=(\"\${_col_vals_${c}[@]}\")"
        local val
        for val in "${_cv[@]}"; do
            _grid_parse_cell "$val"
            vw="$(_str_width "$_cell_val")"
            (( vw > max_vw )) && max_vw=$vw
        done

        # Apply min/max constraints
        local mn="${_COL[mn_${c}]:-0}"
        local mx="${_COL[mx_${c}]:-0}"
        (( mn > 0 && max_vw < mn )) && max_vw=$mn
        (( mx > 0 && max_vw > mx )) && max_vw=$mx

        _COL["w_${c}"]=$max_vw
    done

    _LAY[ncol]="$ncol"
    _LAY[has_header]="$has_header"
}

# ============================================================
# Build: compute block_w and indent
# ============================================================
# g_build [offset]
# offset: -1 (left) .. 0 (center) .. +1 (right)
g_build() {
    local offset="${1:-0}"
    _TERM_W=$(tput cols 2>/dev/null || echo 80)

    local ncol="${_LAY[ncol]:-0}"
    local sep="${_LAY[sep]:-│}"
    local sep_w; sep_w="$(_str_width "$sep")"

    # -- Sum column widths
    local total_cw=0 c
    for (( c=0; c<ncol; c++ )); do
        total_cw=$(( total_cw + ${_COL[w_${c}]:-0} ))
    done

    # -- Inter-column gaps: (ncol-1) × (gap + sep + gap)
    local gap_total=$(( GRID_GAP * 2 + sep_w ))
    local gaps=0
    (( ncol > 1 )) && gaps=$(( (ncol - 1) * gap_total ))

    # -- Total block width
    local bw=$(( GRID_PAD + total_cw + gaps + GRID_PAD ))

    # -- Auto-shrink if wider than terminal
    local max_w=$(( _TERM_W - 2 ))
    if (( bw > max_w && ncol > 0 )); then
        bw=$max_w
        local used=$(( GRID_PAD * 2 + gaps ))
        local last=$(( ncol - 1 ))
        local lw=$(( bw - used ))
        for (( c=0; c<last; c++ )); do
            lw=$(( lw - ${_COL[w_${c}]:-0} ))
        done
        (( lw < 3 )) && lw=3
        _COL["w_${last}"]=$lw
    fi

    # -- Indent for centering
    local range=$(( _TERM_W - bw - 2 ))
    (( range < 0 )) && range=0
    local half=$(( range / 2 ))
    local off_pct=0
    if [[ "$offset" != "NONE" && -n "$offset" ]]; then
        off_pct=$(awk -v o="$offset" 'BEGIN{printf "%d", o*100}' 2>/dev/null || echo 0)
    fi
    local indent=$(( 1 + half + off_pct * half / 100 ))
    [[ "$offset" == "NONE" ]] && indent=1

    _LAY[bw]=$bw
    _LAY[indent]=$indent
}
