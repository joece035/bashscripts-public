#!/bin/bash
# ============================================================
# grid-engine/lib/str.sh — String Utilities (Self-Contained)
# ============================================================
# Visual-width helpers, repeat, truncate — no JOE dependency.
# ============================================================

# -- Visual-width: strip ANSI + count display columns
#   Tier 1: python3 (most accurate with wcwidth)
#   Tier 2: sed strip + wc -m (fallback)
_str_width() {
    local s="$1"
    [[ -z "$s" ]] && { echo 0; return; }

    if command -v python3 &>/dev/null; then
        python3 -c "
import sys, re
s = sys.argv[1]
s = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', s)
w = 0
for ch in s:
    cp = ord(ch)
    if cp < 128: w += 1
    elif cp >= 0x1100 and (
        cp <= 0x115F or cp == 0x2329 or cp == 0x232A or
        (0x2E80 <= cp <= 0x303E) or (0x3040 <= cp <= 0x33BF) or
        (0x3400 <= cp <= 0x4DBF) or (0x4E00 <= cp <= 0x9FFF) or
        (0xA000 <= cp <= 0xA4CF) or (0xAC00 <= cp <= 0xD7AF) or
        (0xF900 <= cp <= 0xFAFF) or (0xFE30 <= cp <= 0xFE6F) or
        (0xFF01 <= cp <= 0xFF60) or (0xFFE0 <= cp <= 0xFFE6) or
        (0x20000 <= cp <= 0x2FFFD) or (0x30000 <= cp <= 0x3FFFD)
    ): w += 2
    else: w += 1
print(w)
" "$s" 2>/dev/null && return
    fi

    # Fallback: strip ANSI, wc -m
    local plain
    plain=$(printf '%s' "$s" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
    printf '%s' "$plain" | wc -m | tr -d ' '
}

# -- Batch visual-width (multiple strings, one python call)
_str_widths() {
    local strs=("$@")
    if (( ${#strs[@]} == 0 )); then return; fi
    if command -v python3 &>/dev/null; then
        printf '%s\n' "${strs[@]}" | python3 -c "
import sys, re
for line in sys.stdin:
    s = line.rstrip('\n')
    s = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', s)
    w = 0
    for ch in s:
        cp = ord(ch)
        if cp < 128: w += 1
        elif cp >= 0x1100 and (
            cp <= 0x115F or cp == 0x2329 or cp == 0x232A or
            (0x2E80 <= cp <= 0x303E) or (0x3040 <= cp <= 0x33BF) or
            (0x3400 <= cp <= 0x4DBF) or (0x4E00 <= cp <= 0x9FFF) or
            (0xA000 <= cp <= 0xA4CF) or (0xAC00 <= cp <= 0xD7AF) or
            (0xF900 <= cp <= 0xFAFF) or (0xFE30 <= cp <= 0xFE6F) or
            (0xFF01 <= cp <= 0xFF60) or (0xFFE0 <= cp <= 0xFFE6) or
            (0x20000 <= cp <= 0x2FFFD) or (0x30000 <= cp <= 0x3FFFD)
        ): w += 2
        else: w += 1
    print(w)
" 2>/dev/null && return
    fi
    # Fallback: one by one
    for s in "${strs[@]}"; do
        _str_width "$s"
    done
}

# -- Repeat char N times
_str_repeat() {
    local char="$1" count="$2"
    (( count <= 0 )) && return 0
    local result=""
    local i
    for (( i=0; i<count; i++ )); do
        result+="$char"
    done
    printf '%s' "$result"
}

# -- Repeat pattern until reaching target visual width
_str_repeat_pattern() {
    local pat="$1" target="$2"
    (( target <= 0 )) && return 0
    [[ -z "$pat" ]] && { _str_repeat " " "$target"; return; }

    local pat_len=${#pat}
    if (( pat_len <= 1 )); then
        _str_repeat "$pat" "$target"
        return
    fi

    local reps=$(( target / pat_len ))
    local rem=$(( target % pat_len ))
    local result=""
    local i
    for (( i=0; i<reps; i++ )); do
        result+="$pat"
    done
    if (( rem > 0 )); then
        result+="${pat:0:$rem}"
    fi
    printf '%s' "$result"
}

# -- Truncate string to visual width (adds … if truncated)
_str_truncate() {
    local s="$1" max_w="$2"
    local vw; vw="$(_str_width "$s")"
    if (( vw <= max_w )); then
        printf '%s' "$s"
        return
    fi
    if command -v python3 &>/dev/null; then
        printf '%s' "$s" | python3 -c "
import sys, re
s = sys.argv[1]
max_w = int(sys.argv[2])
s_clean = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', s)
w = 0
out = []
for ch in s_clean:
    cp = ord(ch)
    cw = 1
    if cp >= 0x1100 and (
        cp <= 0x115F or cp == 0x2329 or cp == 0x232A or
        (0x2E80 <= cp <= 0x303E) or (0x3040 <= cp <= 0x33BF) or
        (0x3400 <= cp <= 0x4DBF) or (0x4E00 <= cp <= 0x9FFF) or
        (0xA000 <= cp <= 0xA4CF) or (0xAC00 <= cp <= 0xD7AF) or
        (0xF900 <= cp <= 0xFAFF) or (0xFE30 <= cp <= 0xFE6F) or
        (0xFF01 <= cp <= 0xFF60) or (0xFFE0 <= cp <= 0xFFE6) or
        (0x20000 <= cp <= 0x2FFFD) or (0x30000 <= cp <= 0x3FFFD)
    ): cw = 2
    if w + cw > max_w - 1:
        print(''.join(out) + '…')
        sys.exit(0)
    out.append(ch)
    w += cw
print(''.join(out))
" "$s" "$max_w" 2>/dev/null && return
    fi
    # Fallback
    printf '%s' "${s:0:$max_w}…"
}

# -- printf -v wrapper (bash + zsh compatible)
_pvar() {
    local _var="$1"; shift
    printf -v "$_var" "$@"
}

# -- Split string on delimiter into named array (bash + zsh)
_split_on() {
    local _arr_name="$1"
    local _str="$2"
    local _delim="${3:-|}"
    if [[ -n "${BASH_VERSION:-}" ]]; then
        local -n _out="$_arr_name"
        IFS="$_delim" read -ra _out <<< "$_str"
    else
        eval "${_arr_name}=(\"\${(@s:${_delim}:)_str}\")"
    fi
}
