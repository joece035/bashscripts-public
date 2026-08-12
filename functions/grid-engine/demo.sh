#!/bin/bash
# ============================================================
# grid-engine/demo.sh — Example Grid Demos
# ============================================================
# Usage:
#   source ~/bashscripts/functions/grid-engine/entry.sh
#   source ~/bashscripts/functions/grid-engine/demo.sh
#
#   demo_all           — show all styles
#   demo_inline        — inline color overrides
#   demo_process       — top processes table
#   demo_disk          — disk usage table
#   demo_custom        — custom columns
# ============================================================

# ============================================================
# demo_all — Show all grid styles with same data
# ============================================================
demo_all() {
    local _demo_rows=(
        "SSH|ACTIVE|192.168.1.100|🟢"
        "Tailscale|ONLINE|Connected|🟢"
        "Syncthing|OK|Syncing|✅"
        "Docker|RUNNING|12 containers|🐳"
        "Uptime|OK|3 days, 2h|⏱️"
    )

    local styles=("grid" "grid_compact" "grid_fancy" "grid_minimal" "grid_rainbow")
    local labels=("── Grid (Default) ──" "── Grid Compact ──" "── Grid Fancy ──" "── Grid Minimal ──" "── Grid Rainbow ──")
    local i=0

    for style in "${styles[@]}"; do
        cn lg b "${labels[$i]}"
        col_reset
        col_add "SERVICE"  "l" 12 0 "118 bi"
        col_add "STATUS"   "c"  8 0 ""
        col_add "DETAILS"  "l" 18 0 ""
        col_add "ICON"     "c"  4 0 ""

        load_theme "$style" "0"
        printf '%s\n' "${_demo_rows[@]}" | grid_default_provider
        echo ""
        (( i++ ))
    done
}

# ============================================================
# demo_inline — Inline color overrides per cell
# ============================================================
demo_inline() {
    cn lg b "── Inline Color Overrides ──"

    col_reset
    col_add "SERVICE" "l" 12 0 ""
    col_add "STATUS"  "c" 8  0 ""
    col_add "HEALTH"  "r" 8  0 ""

    load_theme "grid_fancy" "0"

    local rows=(
        "SSH|ACTIVE|100 bi::100%"
        "Tailscale|OFFLINE|203 bi::WARN"
        "Syncthing|OK|118 bi::GOOD"
        "Docker|DOWN|196 bi::FAIL"
    )
    printf '%s\n' "${rows[@]}" | grid_default_provider
    echo ""
}

# ============================================================
# demo_process — Top processes
# ============================================================
demo_process() {
    cn lg b "── Top Processes ──"

    col_reset
    col_add "PID"    "r" 7  0 ""
    col_add "NAME"   "l" 20 0 ""
    col_add "CPU%"   "r" 5  0 ""
    col_add "MEM%"   "r" 5  0 ""
    col_add "STATE"  "c" 6  0 ""

    load_theme "grid" "0"

    local rows=()
    local line
    while IFS= read -r line; do
        local pid name cpu mem stat
        pid=$(echo "$line" | awk '{print $1}')
        [[ -z "$pid" || "$pid" == "PID" ]] && continue
        name=$(echo "$line" | awk '{print $4}' | sed 's/.*\///' | cut -c1-20)
        cpu=$(echo "$line" | awk '{print $3}')
        mem=$(echo "$line" | awk '{print $4}')
        stat=$(echo "$line" | awk '{print $8}')
        [[ -z "$name" ]] && continue
        rows+=("${pid}|${name}|${cpu}|${mem}|${stat}")
    done < <(ps aux --sort=-%cpu 2>/dev/null | head -11)

    printf '%s\n' "${rows[@]}" | grid_default_provider
    echo ""
}

# ============================================================
# demo_disk — Disk usage
# ============================================================
demo_disk() {
    cn lg b "── Disk Usage ──"

    col_reset
    col_add "MOUNT" "l" 15 0 ""
    col_add "SIZE"  "r" 8  0 ""
    col_add "USED"  "r" 8  0 ""
    col_add "AVAIL" "r" 8  0 ""
    col_add "USE%"  "r" 5  0 ""

    load_theme "grid_compact" "0"

    local rows=()
    local line
    while IFS= read -r line; do
        local mount size used avail pct
        mount=$(echo "$line" | awk '{print $6}')
        size=$(echo "$line" | awk '{print $2}')
        used=$(echo "$line" | awk '{print $3}')
        avail=$(echo "$line" | awk '{print $4}')
        pct=$(echo "$line" | awk '{print $5}')
        rows+=("${mount}|${size}|${used}|${avail}|${pct}")
    done < <(df -h 2>/dev/null | tail -n +2 | grep -E '^/' | head -8)

    printf '%s\n' "${rows[@]}" | grid_default_provider
    echo ""
}

# ============================================================
# demo_custom — Custom columns with inline colors
# ============================================================
demo_custom() {
    cn lg b "── Custom 6-Column Grid ──"

    col_reset
    col_add "ID"      "r" 4  0 ""
    col_add "NAME"    "l" 15 0 ""
    col_add "TYPE"    "c" 8  0 ""
    col_add "SIZE"    "r" 8  0 ""
    col_add "STATUS"  "c" 8  0 ""
    col_add "NOTE"    "l" 20 0 ""

    load_theme "grid_fancy" "0"

    local rows=(
        "1|Main Server|physical|2TB|100 bi::ACTIVE|Production"
        "2|Backup NAS|virtual|8TB|118 bi::OK|Weekly sync"
        "3|Dev Laptop|laptop|512G|203 bi::LOW|Needs cleanup"
        "4|Cloud VPS|cloud|100G|118 bi::OK|AWS us-east-1"
        "5|Old Pi|ARM|32G|196 bi::WARN|SD card failing"
    )
    printf '%s\n' "${rows[@]}" | grid_default_provider
    echo ""
}

# ============================================================
# demo_table_api — grid_table quick API
# ============================================================
demo_table_api() {
    cn lg b "── grid_table API ──"

    grid_table \
        "SERVICE:l:12:0:118 bi" \
        "STATUS:c:8:0:" \
        "VALUE:r:6:0:202 bi" \
        -- \
        "SSH|ACTIVE|OK" \
        "Tailscale|OFFLINE|ERR" \
        "Syncthing|OK|SYNC" \
        "Docker|RUNNING|12"
    echo ""
}

# ============================================================
# Run all demos
# ============================================================
demo_all_demos() {
    cn lg b "╔══════════════════════════════════════════════════╗"
    cn lg b "║       Grid Engine — Full Demo Suite             ║"
    cn lg b "╚══════════════════════════════════════════════════╝"
    echo ""

    demo_all
    demo_inline
    demo_custom
    demo_table_api
    demo_process
    demo_disk

    cn lg b "╔══════════════════════════════════════════════════╗"
    cn lg b "║       Demo Complete!                            ║"
    cn lg b "╚══════════════════════════════════════════════════╝"
}
