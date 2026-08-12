#!/bin/bash
# ============================================================
# grid-engine/lib/render.sh — Grid Renderer
# ============================================================
# Renders N-column grids with per-column alignment.
# Uses _COL[], _LAY[], _THEME[] for context.
#
# Public:
#   render_border_top  render_border_bot
#   render_row         render_header
#   render_mid         render_sep_line
# ============================================================

# -- Get frame chars into hr_l hr_r hm_l hm_r
_get_frame() {
    if [[ "${_THEME[frame_mode]:-}" == "random" ]]; then
        if [[ -z "${_THEME[_cached_frame]:-}" ]]; then
            local -a _pal=()
            local pi
            for (( pi=1; pi<=8; pi++ )); do
                [[ -n "${_THEME[p${pi}]:-}" ]] && _pal+=("${_THEME[p${pi}]}")
            done
            if (( ${#_pal[@]} > 0 )); then
                local rc="${_pal[$(( RANDOM % ${#_pal[@]} ))]}"
                _THEME[_cached_fl]="$(_c_apply "$rc" "${_THEME[fl]:-│}")"
                _THEME[_cached_fr]="$(_c_apply "$rc" "${_THEME[fr]:-│}")"
                _THEME[_cached_frame]=1
            fi
        fi
        hr_l="${_THEME[_cached_fl]:-│}"
        hr_r="${_THEME[_cached_fr]:-│}"
        hm_l="$hr_l"; hm_r="$hr_r"
    else
        hr_l="${_THEME[cc_fl]:-${_THEME[fl]:-│}}"
        hr_r="${_THEME[cc_fr]:-${_THEME[fr]:-│}}"
        hm_l="${_THEME[cc_mfl]:-${_THEME[mfl]:-${_THEME[fl]:-│}}}"
        hm_r="${_THEME[cc_mfr]:-${_THEME[mfr]:-${_THEME[fr]:-│}}}"
    fi
}

# ============================================================
# Align cell within visual width
# ============================================================
_align() {
    local val="$1" w="$2" al="${3:-l}"
    local vw; vw="$(_str_width "$val")"
    local pad=$(( w - vw ))
    (( pad < 0 )) && pad=0

    local lp rp
    case "$al" in
        r) lp=$pad; rp=0 ;;
        c) lp=$(( pad / 2 )); rp=$(( pad - lp )) ;;
        *) lp=0; rp=$pad ;;
    esac

    local out=""
    local _t=""
    (( lp > 0 )) && { _pvar _t '%*s' "$lp" ''; out+="$_t"; }
    out+="$val"
    (( rp > 0 )) && { _pvar _t '%*s' "$rp" ''; out+="$_t"; }
    printf '%s' "$out"
}

# ============================================================
# Border Top
# ============================================================
render_border_top() {
    local w="${_LAY[bw]}" ind="${_LAY[indent]}"
    local pad; _pvar pad '%*s' "$ind" ''

    local ch="${_THEME[bc]:-═}"
    local plain; plain="$(_str_repeat_pattern "$ch" "$w")"

    local border=""
    if [[ "${_THEME[border_mode]:-}" == "rainbow" ]]; then
        local i
        for (( i=0; i<w; i++ )); do
            border+="$(printf '%b' "\e[$(( 31 + (i % 6) ))m${plain:$i:1}\e[0m")"
        done
    elif [[ "${_THEME[border_mode]:-}" == "random" ]]; then
        if [[ -z "${_THEME[_cached_bdr]:-}" ]]; then
            local -a _pal=()
            local pi
            for (( pi=1; pi<=8; pi++ )); do
                [[ -n "${_THEME[p${pi}]:-}" ]] && _pal+=("${_THEME[p${pi}]}")
            done
            if (( ${#_pal[@]} > 0 )); then
                local rc="${_pal[$(( RANDOM % ${#_pal[@]} ))]}"
                _THEME[_cached_bdr]="$(_c_apply "$rc" "$plain")"
            fi
        fi
        border="${_THEME[_cached_bdr]:-$plain}"
    else
        border="$(_c_apply "${_THEME[bc_c]:-}" "$plain")"
    fi

    echo -e "${pad}${border}"
}

# ============================================================
# Border Bot
# ============================================================
render_border_bot() {
    local w="${_LAY[bw]}" ind="${_LAY[indent]}"
    local pad; _pvar pad '%*s' "$ind" ''

    local ch="${_THEME[bbc]:-${_THEME[bc]:-═}}"
    local plain; plain="$(_str_repeat_pattern "$ch" "$w")"

    local border=""
    if [[ "${_THEME[border_mode]:-}" == "rainbow" ]]; then
        local i
        for (( i=0; i<w; i++ )); do
            border+="$(printf '%b' "\e[$(( 31 + (i % 6) ))m${plain:$i:1}\e[0m")"
        done
    elif [[ "${_THEME[border_mode]:-}" == "random" ]]; then
        border="${_THEME[_cached_bdr]:-$plain}"
    else
        border="$(_c_apply "${_THEME[bbc_c]:-}" "$plain")"
    fi

    echo -e "${pad}${border}"
}

# ============================================================
# Mid separator (between rows)
# ============================================================
render_mid() {
    local ind="${_LAY[indent]}" w="${_LAY[bw]}"
    local pad; _pvar pad '%*s' "$ind" ''

    local hr_l hr_r hm_l hm_r
    _get_frame

    local hm_lw; hm_lw="$(_str_width "$hm_l")"
    local hm_rw; hm_rw="$(_str_width "$hm_r")"
    local inner=$(( w - hm_lw - hm_rw ))
    (( inner < 0 )) && inner=0

    local mc="${_THEME[mlc]:-─}"
    local mid; mid="$(_str_repeat_pattern "$mc" "$inner")"

    if [[ "${_THEME[mid_mode]:-}" == "random" ]]; then
        local -a _pal=()
        local pi
        for (( pi=1; pi<=8; pi++ )); do
            [[ -n "${_THEME[p${pi}]:-}" ]] && _pal+=("${_THEME[p${pi}]}")
        done
        if (( ${#_pal[@]} > 0 )); then
            local rc="${_pal[$(( RANDOM % ${#_pal[@]} ))]}"
            mid="$(_c_apply "$rc" "$mid")"
        fi
    else
        mid="$(_c_apply "${_THEME[mlc_c]:-}" "$mid")"
    fi

    echo -e "${pad}${hm_l}${mid}${hm_r}"
}

# ============================================================
# Header row (column names)
# ============================================================
render_header() {
    local ncol="${_LAY[ncol]:-0}"
    (( ncol == 0 )) && return 0

    local ind="${_LAY[indent]}"
    local sep="${_LAY[sep]:-│}"
    local pad; _pvar pad '%*s' "$ind" ''

    local hr_l hr_r hm_l hm_r
    _get_frame

    local row="" c
    for (( c=0; c<ncol; c++ )); do
        local cw="${_COL[w_${c}]:-0}"
        local hdr="${_COL[n_${c}]:-}"
        local al="${_COL[a_${c}]:-l}"
        local colored; colored="$(_c_apply "${_THEME[hc]:-bi}" "$hdr")"
        row+="$(_align "$colored" "$cw" "$al")"
        if (( c < ncol - 1 )); then
            row+="$(_c_apply "${_THEME[sc_c]:-}" "$sep")"
        fi
    done

    echo -e "${pad}${hr_l}${row}${hr_r}"
}

# ============================================================
# Data row
# ============================================================
render_row() {
    local row_str="$1"
    local ncol="${_LAY[ncol]:-0}"
    (( ncol == 0 )) && return 0

    local ind="${_LAY[indent]}"
    local sep="${_LAY[sep]:-│}"
    local pad; _pvar pad '%*s' "$ind" ''

    local hr_l hr_r hm_l hm_r
    _get_frame

    _split_on _g_parts "$row_str"
    local nf=${#_g_parts[@]}

    local row="" c
    for (( c=0; c<ncol; c++ )); do
        local cw="${_COL[w_${c}]:-0}"
        local al="${_COL[a_${c}]:-l}"

        # Get value
        if (( c < nf )); then
            _grid_parse_cell "${_g_parts[$c]}"
        else
            _cell_val=""; _cell_clr=""
        fi

        # Determine color: inline > column default > theme default
        local clr=""
        [[ -n "$_cell_clr" ]]       && clr="$_cell_clr"
        [[ -z "$clr" ]] && [[ -n "${_COL[cl_${c}]:-}" ]] && clr="${_COL[cl_${c}]}"
        [[ -z "$clr" ]]             && clr="${_THEME[vc]:-}"

        # Truncate if needed
        local mx="${_COL[mx_${c}]:-0}"
        if (( mx > 0 )); then
            local vw; vw="$(_str_width "$_cell_val")"
            (( vw > mx )) && _cell_val="$(_str_truncate "$_cell_val" $((mx - 1)))…"
        fi

        # Apply color + align
        local colored
        [[ -n "$clr" ]] && colored="$(_c_apply "$clr" "$_cell_val")" || colored="$_cell_val"
        row+="$(_align "$colored" "$cw" "$al")"

        if (( c < ncol - 1 )); then
            row+="$(_c_apply "${_THEME[sc_c]:-}" "$sep")"
        fi
    done

    echo -e "${pad}${hr_l}${row}${hr_r}"
}

# ============================================================
# Separator line (no frame)
# ============================================================
render_sep_line() {
    local w="${_LAY[bw]}" ind="${_LAY[indent]}"
    local pad; _pvar pad '%*s' "$ind" ''
    local mc="${_THEME[mlc]:-─}"
    local line; line="$(_str_repeat_pattern "$mc" "$w")"
    line="$(_c_apply "${_THEME[mlc_c]:-}" "$line")"
    echo -e "${pad}${line}"
}
