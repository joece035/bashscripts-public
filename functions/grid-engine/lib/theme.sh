#!/bin/bash
# ============================================================
# grid-engine/lib/theme.sh — Grid Theme System
# ============================================================
# Defines grid styles (colors, borders, frames).
# _THEME[] associative array stores all visual settings.
#
# Theme keys:
#   bc, bbc      — border char top/bottom
#   bc_c, bbc_c  — border color top/bottom
#   border_mode  — "no" | "random" | "rainbow"
#   fl, fr       — frame char left/right
#   mfl, mfr     — mid-frame char left/right
#   mlc          — mid-line char
#   mlc_c        — mid-line color
#   mid_mode     — "no" | "random"
#   hc           — header color
#   vc           — value (cell) default color
#   sc_c         — separator color
#   offset       — position offset
# ============================================================

if [[ -n "${BASH_VERSION:-}" ]]; then
    declare -g -A _THEME 2>/dev/null || true
else
    typeset -g -A _THEME 2>/dev/null || true
fi

# -- set_ helper (same pattern as JOE)
set_() { _pvar "$1" '%s' "$2"; }

# ============================================================
# Style: grid (default) — clean table with │ separators
# ============================================================
_style_grid() {
    set_ bc       "═"
    set_ bbc      "═"
    set_ bc_c     "lb b"
    set_ bbc_c    "lb b"
    set_ border_mode "no"

    set_ fl       "│"
    set_ fr       "│"
    set_ mfl      "│"
    set_ mfr      "│"

    set_ mlc      "─"
    set_ mlc_c    ""
    set_ mid_mode "no"

    set_ hc       "bi"
    set_ vc       ""
    set_ sc_c     ""
    set_ offset   "0"
}

# ============================================================
# Style: grid_compact — no frame, tight spacing
# ============================================================
_style_grid_compact() {
    set_ bc       "─"
    set_ bbc      "─"
    set_ bc_c     "lg"
    set_ bbc_c    "lg"
    set_ border_mode "no"

    set_ fl       ""
    set_ fr       ""
    set_ mfl      ""
    set_ mfr      ""

    set_ mlc      "·"
    set_ mlc_c    ""
    set_ mid_mode "no"

    set_ hc       "b bi"
    set_ vc       ""
    set_ sc_c     ""
    set_ offset   "0"
}

# ============================================================
# Style: grid_fancy — unicode box drawing
# ============================================================
_style_grid_fancy() {
    set_ bc       "━"
    set_ bbc      "━"
    set_ bc_c     "lb b"
    set_ bbc_c    "lb b"
    set_ border_mode "no"

    set_ fl       "┃"
    set_ fr       "┃"
    set_ mfl      "┃"
    set_ mfr      "┃"

    set_ mlc      "┅"
    set_ mlc_c    ""
    set_ mid_mode "no"

    set_ hc       "lb b"
    set_ vc       ""
    set_ sc_c     ""
    set_ offset   "0"
}

# ============================================================
# Style: grid_minimal — no borders, no frame
# ============================================================
_style_grid_minimal() {
    set_ bc       ""
    set_ bbc      ""
    set_ bc_c     ""
    set_ bbc_c    ""
    set_ border_mode "no"

    set_ fl       ""
    set_ fr       ""
    set_ mfl      ""
    set_ mfr      ""

    set_ mlc      ""
    set_ mlc_c    ""
    set_ mid_mode "no"

    set_ hc       "bi"
    set_ vc       ""
    set_ sc_c     "  "
    set_ offset   "0"
}

# ============================================================
# Style: grid_rainbow — rainbow borders
# ============================================================
_style_grid_rainbow() {
    set_ bc       "◆"
    set_ bbc      "◆"
    set_ bc_c     ""
    set_ bbc_c    ""
    set_ border_mode "rainbow"

    set_ fl       "│"
    set_ fr       "│"
    set_ mfl      "│"
    set_ mfr      "│"

    set_ mlc      "─"
    set_ mlc_c    ""
    set_ mid_mode "random"

    set_ hc       "bi"
    set_ vc       ""
    set_ sc_c     ""
    set_ offset   "0"
}

# ============================================================
# Load theme by name
# ============================================================
# load_theme <style_name> [offset]
load_theme() {
    local style="${1:-grid}"
    local offset="${2:-}"

    # Strip "grid_" prefix if present
    style="${style#grid_}"

    local func="_style_grid_${style}"
    if declare -f "$func" >/dev/null 2>&1; then
        "$func"
    else
        _style_grid
    fi

    # Override offset if provided
    [[ -n "$offset" ]] && _THEME[offset]="$offset"
}
