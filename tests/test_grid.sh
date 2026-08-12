#!/bin/bash
# ============================================================
# test_grid.sh — Grid Engine Test Script
# ============================================================
# Tests the flexible N-column grid engine.
#
# Usage:
#   bash test_grid.sh
#   source test_grid.sh && test_all
# ============================================================

# -- Source the grid engine
_GRID_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
source "${_GRID_TEST_DIR}/../block/grid/entry.sh"
source "${_GRID_TEST_DIR}/../block/grid/providers.sh"

# ============================================================
# Test Helpers
# ============================================================
_pass=0
_fail=0

_test_header() {
    echo ""
    cn lg b "╔══════════════════════════════════════════════╗"
    cn lg b "║  TEST: $1"
    cn lg b "╚══════════════════════════════════════════════╝"
}

_assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        cn g "  ✓ $label"
        (( _pass++ ))
    else
        cn r "  ✗ $label"
        cn r "    expected: '$expected'"
        cn r "    actual:   '$actual'"
        (( _fail++ ))
    fi
}

# ============================================================
# Test 1: Column Definition API
# ============================================================
test_col_define() {
    _test_header "Column Definition API"

    _grid_col_reset
    local count; count="$(_grid_col_count)"
    _assert_eq "reset count=0" "0" "$count"

    _grid_col_add "STATUS" "l" 10 0 "118 bi"
    count="$(_grid_col_count)"
    _assert_eq "add 1 col → count=1" "1" "$count"

    local name; name="$(_grid_col_get 0 name)"
    _assert_eq "col0 name=STATUS" "STATUS" "$name"

    local align; align="$(_grid_col_get 0 align)"
    _assert_eq "col0 align=l" "l" "$align"

    _grid_col_add "VALUE" "r" 8 0 "202 bi"
    count="$(_grid_col_count)"
    _assert_eq "add 2nd col → count=2" "2" "$count"

    name="$(_grid_col_get 1 name)"
    _assert_eq "col1 name=VALUE" "VALUE" "$name"
}

# ============================================================
# Test 2: Cell Parser (inline color override)
# ============================================================
test_cell_parser() {
    _test_header "Cell Parser (inline color)"

    _grid_parse_cell "hello"
    _assert_eq "plain value" "hello" "$_cell_value"
    _assert_eq "plain color (empty)" "" "$_cell_color"

    _grid_parse_cell "118 bi::ONLINE"
    _assert_eq "colored value" "ONLINE" "$_cell_value"
    _assert_eq "colored color" "118 bi" "$_cell_color"

    _grid_parse_cell "r::99%"
    _assert_eq "r color value" "99%" "$_cell_value"
    _assert_eq "r color spec" "r" "$_cell_color"
}

# ============================================================
# Test 3: 2-Column Grid
# ============================================================
test_2col_grid() {
    _test_header "2-Column Grid"

    _grid_col_reset
    _grid_col_add "LABEL" "l" 10 0 ""
    _grid_col_add "VALUE" "r" 8 0 ""

    _blk_init
    _load_grid_theme "grid_default" "0"

    local rows=(
        "Name|Alice"
        "Age|30"
        "City|Bangkok"
    )
    printf '%s\n' "${rows[@]}" | grid_dashboard
    echo ""
    cn g "  ✓ 2-column grid rendered"
    (( _pass++ ))
}

# ============================================================
# Test 4: 4-Column Grid (JOE equivalent)
# ============================================================
test_4col_grid() {
    _test_header "4-Column Grid (JOE-style)"

    _grid_col_reset
    _grid_col_add "SERVICE"  "l" 12 0 "118 bi"
    _grid_col_add "STATUS"   "c"  8 0 ""
    _grid_col_add "DETAILS"  "l" 15 0 ""
    _grid_col_add "ICON"     "c"  4 0 ""

    _blk_init
    _load_grid_theme "grid_default" "0"

    local rows=(
        "SSH|ACTIVE|192.168.1.100|🟢"
        "Tailscale|ONLINE|Connected|🟢"
        "Syncthing|OK|Syncing|✅"
    )
    printf '%s\n' "${rows[@]}" | grid_dashboard
    echo ""
    cn g "  ✓ 4-column grid rendered"
    (( _pass++ ))
}

# ============================================================
# Test 5: 6-Column Grid (wide table)
# ============================================================
test_6col_grid() {
    _test_header "6-Column Grid (wide table)"

    _grid_col_reset
    _grid_col_add "PID"     "r" 7  0 ""
    _grid_col_add "USER"    "l" 10 0 ""
    _grid_col_add "CPU%"    "r" 5  0 ""
    _grid_col_add "MEM%"    "r" 5  0 ""
    _grid_col_add "STATE"   "c" 6  0 ""
    _grid_col_add "COMMAND" "l" 20 0 ""

    _blk_init
    _load_grid_theme "grid_compact" "0"

    local rows=(
        "1|root|0.0|0.1|S|init"
        "1234|user|2.5|5.1|S|bash"
        "5678|user|15.3|12.0|R|python3"
        "9012|www|0.1|0.3|S|nginx"
    )
    printf '%s\n' "${rows[@]}" | grid_dashboard
    echo ""
    cn g "  ✓ 6-column grid rendered"
    (( _pass++ ))
}

# ============================================================
# Test 6: Inline Color Overrides
# ============================================================
test_inline_colors() {
    _test_header "Inline Color Overrides"

    _grid_col_reset
    _grid_col_add "SERVICE" "l" 12 0 ""
    _grid_col_add "STATUS"  "c" 8  0 ""
    _grid_col_add "HEALTH"  "r" 8  0 ""

    _blk_init
    _load_grid_theme "grid_fancy" "0"

    local rows=(
        "SSH|ACTIVE|100 bi::100%"
        "Tailscale|OFFLINE|203 bi::WARN"
        "Syncthing|OK|118 bi::GOOD"
        "Docker|DOWN|196 bi::FAIL"
    )
    printf '%s\n' "${rows[@]}" | grid_dashboard
    echo ""
    cn g "  ✓ inline color overrides rendered"
    (( _pass++ ))
}

# ============================================================
# Test 7: All Grid Styles
# ============================================================
test_all_styles() {
    _test_header "All Grid Styles"

    local styles=("grid_default" "grid_compact" "grid_fancy" "grid_minimal")
    local labels=("Default" "Compact" "Fancy" "Minimal")
    local i=0

    for style in "${styles[@]}"; do
        cn y "  ─── Style: ${labels[$i]} ───"

        _grid_col_reset
        _grid_col_add "SERVICE" "l" 12 0 ""
        _grid_col_add "STATUS"  "c" 8  0 ""
        _grid_col_add "VALUE"   "r" 6  0 ""

        _blk_init
        _load_grid_theme "$style" "0"

        local rows=(
            "SSH|ACTIVE|OK"
            "TS|OFFLINE|ERR"
            "ST|OK|SYNC"
        )
        printf '%s\n' "${rows[@]}" | grid_dashboard
        echo ""
        (( i++ ))
    done
    cn g "  ✓ all 4 styles rendered"
    (( _pass++ ))
}

# ============================================================
# Test 8: Provider Functions
# ============================================================
test_providers() {
    _test_header "Provider Functions"

    cn y "  ─── grid_status ───"
    grid_status
    echo ""

    cn y "  ─── grid_disk ───"
    grid_disk
    echo ""

    cn g "  ✓ providers rendered"
    (( _pass++ ))
}

# ============================================================
# Test 9: grid_table (argument-based API)
# ============================================================
test_grid_table() {
    _test_header "grid_table (argument API)"

    grid_table \
        "SERVICE:l:12:0:" \
        "STATUS:c:8:0:" \
        "VALUE:r:6:0:" \
        -- \
        "SSH|ACTIVE|OK" \
        "TS|OFFLINE|ERR" \
        "ST|OK|SYNC"
    echo ""
    cn g "  ✓ grid_table rendered"
    (( _pass++ ))
}

# ============================================================
# Test 10: Auto-shrink (wide columns on narrow terminal)
# ============================================================
test_auto_shrink() {
    _test_header "Auto-shrink (80-col terminal)"

    _grid_col_reset
    _grid_col_add "SERVICE"  "l" 20 0 ""
    _grid_col_add "STATUS"   "c" 10 0 ""
    _grid_col_add "DETAILS"  "l" 30 0 ""
    _grid_col_add "EXTRA"    "l" 20 0 ""

    _blk_init
    _load_grid_theme "grid_default" "0"

    local rows=(
        "Very Long Service Name|ACTIVE|Some very long detail text here|Extra info"
        "Another Service|OFFLINE|More details|More info"
    )
    printf '%s\n' "${rows[@]}" | grid_dashboard
    echo ""
    cn g "  ✓ auto-shrink handled (if terminal < block_w)"
    (( _pass++ ))
}

# ============================================================
# Run All Tests
# ============================================================
test_all() {
    cn lg b "╔══════════════════════════════════════════════╗"
    cn lg b "║     JOE Grid Engine — Test Suite            ║"
    cn lg b "╚══════════════════════════════════════════════╝"

    test_col_define
    test_cell_parser
    test_2col_grid
    test_4col_grid
    test_6col_grid
    test_inline_colors
    test_all_styles
    test_providers
    test_grid_table
    test_auto_shrink

    echo ""
    cn lg b "╔══════════════════════════════════════════════╗"
    cn lg b "║  RESULTS: $_pass passed, $_fail failed"
    cn lg b "╚══════════════════════════════════════════════╝"

    (( _fail > 0 )) && return 1 || return 0
}

# -- Auto-run if executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]] || [[ "${(%):-%x}" == "$0" ]]; then
    test_all
fi
