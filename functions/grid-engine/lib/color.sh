#!/bin/bash
# ============================================================
# grid-engine/lib/color.sh — Color Helpers
# ============================================================
# Loads 01-colors.sh from SSOT, provides _c_apply().
# ============================================================

# -- Resolve SSOT root
_GRID_SSOT="${SCRIPTS_PATH:-$HOME/bashscripts}"

# -- Source 01-colors.sh if not already loaded
if [[ -z "${RESET:-}" ]]; then
    [[ -f "${_GRID_SSOT}/core/01-colors.sh" ]] && source "${_GRID_SSOT}/core/01-colors.sh"
    [[ -f "${_GRID_SSOT}/01-colors.sh" ]] && source "${_GRID_SSOT}/01-colors.sh"
fi

# -- Apply color spec to a string
#   _c_apply "118 bi" "text"  → colored text
#   _c_apply "" "text"        → plain text
_c_apply() {
    local spec="$1" text="$2"
    [[ -z "$spec" ]] && { printf '%s' "$text"; return; }

    # spec format: "color_name style" or "number style"
    # Uses c() or cn() from 01-colors.sh if available
    if declare -f c &>/dev/null; then
        # c() takes: c <color> <style> <text>
        local parts=($spec)
        local c1="${parts[0]:-}"
        local c2="${parts[1]:-}"
        c "$c1" "$c2" "$text" 2>/dev/null && return
    fi

    # Fallback: raw ANSI
    printf '%s' "$text"
}

# -- Apply color spec (alias: _apply_color_to)
_apply_color_to() { _c_apply "$1" "$2"; }
