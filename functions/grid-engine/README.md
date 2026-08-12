# Grid Engine — Flexible N-Column Grid Renderer

Self-contained terminal grid template engine.  
**ไม่ fix columns** — กำหนดกี่ column ก็ได้, alignment/color ต่อ column.

## Quick Start

```bash
source ~/bashscripts/functions/grid-engine/entry.sh

# 1. Define columns
col_reset
col_add "SERVICE"  "l" 12 0 "118 bi"   # name:align:min_w:max_w:color
col_add "STATUS"   "c"  8 0 ""
col_add "VALUE"    "r"  6 0 "202 bi"

# 2. Render
grid                    # default style
grid compact            # tight spacing
grid fancy              # box drawing chars
grid minimal            # no borders
grid rainbow            # rainbow borders
```

## API Reference

### Column Definitions

```bash
col_reset                           # clear all columns
col_add <name> [align] [min_w] [max_w] [color]
col_define <index> <name> [align] [min_w] [max_w] [color]
col_count                           # return column count
col_get <index> <field>             # field: name|align|min_w|max_w|color
```

**Align:** `l` (left) | `c` (center) | `r` (right)  
**Color:** any spec from `01-colors.sh` (e.g. `"118 bi"`, `"r b"`, `""` for default)

### Rendering

```bash
grid [style] [offset]               # main entry point
grid_table "col:def" ... -- "row" ...   # quick table from args
grid_random [pure|s]                # random style
grid_set_provider <func>            # set data provider
grid_from --cols ... --rows ... --style ... --offset ...
```

### Inline Color Override

Any cell can override its color: `"color_spec::value"`

```bash
rows=(
    "SSH|ACTIVE|100 bi::100%"       # green "100%"
    "TS|OFFLINE|203 bi::WARN"       # yellow "WARN"
    "Docker|DOWN|196 bi::FAIL"      # red "FAIL"
)
```

### Grid Styles

| Style | Frame | Border | Use Case |
|-------|-------|--------|----------|
| `grid` | `│` | `═` | General dashboard |
| `grid_compact` | (none) | `─` | Tight tables |
| `grid_fancy` | `┃` | `━` | Decorated display |
| `grid_minimal` | (none) | (none) | Clean aligned columns |
| `grid_rainbow` | `│` | `◆` | Rainbow borders |

## Examples

### 2-Column Table

```bash
col_reset
col_add "LABEL" "l" 12 0 ""
col_add "VALUE" "r" 10 0 "202 bi"
grid

# Input:
# Name|Alice
# Age|30
# City|Bangkok
```

### 6-Column Process Table

```bash
col_reset
col_add "PID"    "r" 7  0 ""
col_add "USER"   "l" 10 0 ""
col_add "CPU%"   "r" 5  0 ""
col_add "MEM%"   "r" 5  0 ""
col_add "STATE"  "c" 6  0 ""
col_add "CMD"    "l" 20 0 ""
grid_compact
```

### Quick API (grid_table)

```bash
grid_table \
    "NAME:l:10:0:" \
    "CPU:r:6:0:203 bi" \
    "MEM:r:6:0:118 bi" \
    -- \
    "bash|2.5|5.1" \
    "python|15.3|12.0"
```

## Architecture

```
entry.sh ─── Public API (grid, grid_table, grid_random)
  ├── lib/str.sh    — Visual width, repeat, truncate
  ├── lib/color.sh  — _c_apply (loads 01-colors.sh)
  ├── lib/cols.sh   — Column defs, scan, layout
  ├── lib/theme.sh  — Style definitions
  └── lib/render.sh — Renderer (row, header, border, mid)
```

## Files

```
functions/grid-engine/
├── entry.sh       # Public API
├── demo.sh        # Example demos
├── README.md      # This file
└── lib/
    ├── str.sh     # String utilities
    ├── color.sh   # Color helpers
    ├── cols.sh    # Column definitions & layout
    ├── theme.sh   # Theme system
    └── render.sh  # Grid renderer
```
