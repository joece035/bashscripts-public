#!/bin/bash
# ============================================================
# grid-engine/test.sh — Grid Engine Test Suite
# ============================================================
# Usage: bash ~/bashscripts/functions/grid-engine/test.sh
# ============================================================

_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source "${_SRC_DIR}/entry.sh"

_pass=0; _fail=0

_t() { echo ""; cn lg b "══ TEST: $1 ══"; }
_ok() { cn g "  ✓ $1"; (( _pass++ )); }
_fail_msg() { cn r "  ✗ $1 — expected '$2', got '$3'"; (( _fail++ )); }

# ── Test 1: Column API ────────────────────────────────────
_t "Column API"
col_reset
[[ $(col_count) == "0" ]] && _ok "reset → 0" || _fail_msg "count" "0" "$(col_count)"

col_add "NAME" "l" 10 0 ""
[[ $(col_count) == "1" ]] && _ok "add 1 → count 1" || _fail_msg "count" "1" "$(col_count)"

n=$(col_get 0 name); [[ "$n" == "NAME" ]] && _ok "col0 name=NAME" || _fail_msg "name" "NAME" "$n"
a=$(col_get 0 align); [[ "$a" == "l" ]] && _ok "col0 align=l" || _fail_msg "align" "l" "$a"

col_add "CPU" "r" 6 0 "203 bi"
[[ $(col_count) == "2" ]] && _ok "add 2nd → count 2" || _fail_msg "count" "2" "$(col_count)"

# ── Test 2: Cell Parser ───────────────────────────────────
_t "Cell Parser"
_grid_parse_cell "hello"
[[ "$_cell_val" == "hello" && "$_cell_clr" == "" ]] && _ok "plain value" || _fail_msg "plain" "hello|''" "$_cell_val|$_cell_clr"

_grid_parse_cell "118 bi::ONLINE"
[[ "$_cell_val" == "ONLINE" && "$_cell_clr" == "118 bi" ]] && _ok "colored value" || _fail_msg "colored" "ONLINE|118 bi" "$_cell_val|$_cell_clr"

# ── Test 3: 2-Column Grid ────────────────────────────────
_t "2-Column Grid"
col_reset; col_add "LABEL" "l" 10 0 ""; col_add "VALUE" "r" 8 0 ""
load_theme "grid" "0"
printf '%s\n' "Name|Alice" "Age|30" | grid_default_provider
_ok "2-col rendered"

# ── Test 4: 4-Column Grid ────────────────────────────────
_t "4-Column Grid"
col_reset
col_add "SERVICE" "l" 12 0 "118 bi"
col_add "STATUS"  "c"  8 0 ""
col_add "DETAILS" "l" 15 0 ""
col_add "ICON"    "c"  4 0 ""
load_theme "grid" "0"
printf '%s\n' "SSH|ACTIVE|192.168.1.100|🟢" "TS|ONLINE|Connected|🟢" | grid_default_provider
_ok "4-col rendered"

# ── Test 5: 6-Column Grid ────────────────────────────────
_t "6-Column Grid (wide)"
col_reset
col_add "PID"   "r" 7  0 ""
col_add "USER"  "l" 10 0 ""
col_add "CPU%"  "r" 5  0 ""
col_add "MEM%"  "r" 5  0 ""
col_add "STATE" "c" 6  0 ""
col_add "CMD"   "l" 20 0 ""
load_theme "grid_compact" "0"
printf '%s\n' "1|root|0.0|0.1|S|init" "1234|user|2.5|5.1|S|bash" | grid_default_provider
_ok "6-col rendered"

# ── Test 6: Inline Colors ────────────────────────────────
_t "Inline Color Overrides"
col_reset; col_add "SVC" "l" 10 0 ""; col_add "HEALTH" "r" 8 0 ""
load_theme "grid_fancy" "0"
printf '%s\n' "SSH|100 bi::100%" "TS|203 bi::WARN" | grid_default_provider
_ok "inline colors rendered"

# ── Test 7: All Styles ───────────────────────────────────
_t "All Styles"
for s in grid grid_compact grid_fancy grid_minimal grid_rainbow; do
    col_reset; col_add "A" "l" 8 0 ""; col_add "B" "r" 6 0 ""
    load_theme "$s" "0"
    printf '%s\n' "foo|123" "bar|456" | grid_default_provider
    _ok "style $s"
done

# ── Test 8: grid_table API ───────────────────────────────
_t "grid_table API"
grid_table "X:l:5:0:" "Y:r:5:0:" -- "a|1" "b|2"
_ok "grid_table rendered"

# ── Test 9: grid_from API ────────────────────────────────
_t "grid_from API"
grid_from \
    --cols "A:l:8:0:" "B:r:6:0:" \
    --rows "x|100" "y|200" \
    --style grid_fancy
_ok "grid_from rendered"

# ── Summary ──────────────────────────────────────────────
echo ""
cn lg b "══════════════════════════════════════════"
cn lg b "  RESULTS: $_pass passed, $_fail failed"
cn lg b "══════════════════════════════════════════"

(( _fail > 0 )) && exit 1 || exit 0
