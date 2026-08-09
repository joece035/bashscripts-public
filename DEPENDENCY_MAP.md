# Dependency Map — bashscripts

> Auto-generated dependency analysis for repo split planning.
> Last updated: 2026-08-09

---

## Boot Sequence (`joe.sh`)

```
joe.sh (entry point)
  ├── 00-env.sh          # Environment variables, paths
  ├── 01-colors.sh       # Color system (c/rc/ctab/hline)
  ├── 3worlds.sh         # Multi-env detection
  ├── 02-aliases.sh      # Shell aliases
  ├── profiles.sh        # Profile switching
  ├── theme.sh           # Terminal theme
  ├── functions/*.sh     # ALL function files (glob)
  ├── joe-block/entry.sh # Block engine
  └── syncctl/syncctl    # Syncthing manager
```

---

## Core Dependencies

### `00-env.sh`
- **Sourced by:** `joe.sh`, `11-bash-manager.sh`
- **Depends on:** nothing (leaf)

### `01-colors.sh`
- **Sourced by:** `joe.sh`, `11-bash-manager.sh`, `joe-block/block/theme.sh`
- **Depends on:** nothing (leaf)

### `3worlds.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** `00-env.sh`

### `02-aliases.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** `00-env.sh`, `tools/merge.sh`

### `profiles.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** `00-env.sh`

### `theme.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** `01-colors.sh`

---

## Functions Library

### `00-fm-loader.sh` (File Manager Integration)
- **Sourced by:** `joe.sh`
- **Depends on:**
  - `11-bash-manager.sh`
  - `joe-block/entry.sh`
  - `joe-block/styles/block_style.sh`
  - `tools/hermes.sh`, `tools/merge.sh`, `tools/wtf.sh`, `tools/ai_block.sh`
  - `lessons/exercise/01-exercise_joe.sh`

### `00.1-function-tools.sh` (Shared Tools)
- **Sourced by:** `joe.sh`, `joe-block/block/theme.sh`, `lessons/exercise/01-exercise_joe.sh`
- **Depends on:** `tools/hermes.sh`, `syncctl/syncctl`

### `11-bash-manager.sh` (File Manager CLI)
- **Sourced by:** `joe.sh`, `00-fm-loader.sh`
- **Depends on:** `joe.sh` (fallback boot), `01-colors.sh`, `00-env.sh`

### `02-systems.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** external `.env` files

### `03-fpath.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** `joe-block/entry.sh`

### `04-openclaw.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** external `$OP_DIR/*.env`

### `05-pathx.sh`, `05-project.sh`, `07-wtf.sh`, `08-nexus.sh`, `09-all_block_status.sh`, `10-ai.sh`, `12-git.sh`, `tools.sh`
- **Sourced by:** `joe.sh`
- **Depends on:** minimal / external only

---

## Block Engine

### `joe-block/entry.sh` (Public API)
- **Sourced by:** `joe.sh`, `00-fm-loader.sh`, `03-fpath.sh`, `tools/ai_block.sh`
- **Depends on:**
  - `joe-block/block/utils.sh`
  - `joe-block/block/layout.sh`
  - `joe-block/block/theme.sh`
  - `joe-block/block/renderer.sh`
  - `joe-block/block/status.sh`

### `joe-block/block/theme.sh` ⚠️ CROSS-DEPENDENCY
- **Depends on:**
  - `01-colors.sh` ← **core**
  - `00.1-function-tools.sh` ← **core**
  - `joe-block/styles/block_style.sh` ← **engine**
  - `lessons/custom_style.sh` ← **lessons**

---

## Tools

### `syncctl/syncctl` (Self-contained)
- **Sourced by:** `joe.sh`, `00.1-function-tools.sh`
- **Internal chain:** `syncctl` → `lib/*.sh` (all use `${SYNCCTL_LIB_DIR}`)

### `tools/hermes.sh`
- **Sourced by:** `00-fm-loader.sh`, `00.1-function-tools.sh`

### `tools/ai_block.sh`
- **Sourced by:** `00-fm-loader.sh`
- **Depends on:** `joe-block/entry.sh`

### `tools/merge.sh`
- **Sourced by:** `00-fm-loader.sh`, `02-aliases.sh`

### `tools/wtf.sh`
- **Sourced by:** `00-fm-loader.sh`

---

## Lessons

### `lessons/custom_style.sh`
- **Sourced by:** `joe-block/block/theme.sh`

### `lessons/exercise/01-exercise_joe.sh`
- **Sourced by:** `00-fm-loader.sh`
- **Depends on:**
  - `01-colors.sh` (via `_BS_ROOT`)
  - `00.1-function-tools.sh`
  - `02-exercise_block_style.sh`
  - `03-exercise_status.sh`

---

## Repo Split Boundary Analysis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CORE (bashscripts-core)                              │
│                                                                             │
│  00-env.sh, 01-colors.sh, 3worlds.sh, 02-aliases.sh, profiles.sh,         │
│  theme.sh, .zsh-bash-compat.sh                                              │
│                                                                             │
│  functions/:                                                                │
│    00-fm-loader.sh*, 00.1-function-tools.sh*, 11-bash-manager.sh*          │
│    02-systems.sh, 03-fpath.sh*, 04-openclaw.sh, 05-pathx.sh                │
│    05-project.sh, 07-wtf.sh, 08-nexus.sh, 09-all_block_status.sh           │
│    10-ai.sh, 12-git.sh, tools.sh                                            │
│                                                                             │
│  tools/: hermes.sh, merge.sh, wtf.sh, color-chart.sh, git-easy.sh          │
│          ssot-audit.sh, safe-edit.sh, patch_theme.sh                        │
│          Fresh_termux_fullsetup_SSOT.sh (setup script)                      │
│                                                                             │
│  joe.sh (CLI entry point)                                                   │
│  ble-test.sh                                                                │
└────────────┬────────────────────────────┬───────────────────────┬────────────┘
             │                            │                       │
             ▼                            ▼                       ▼
┌────────────────────────┐  ┌─────────────────────────┐  ┌────────────────────┐
│ BLOCK ENGINE           │  │ LESSONS                 │  │ SYNCCTL            │
│ (joe-block)            │  │ (bashscripts-lessons)   │  │ (syncctl)          │
│                        │  │                         │  │                    │
│ joe-block/             │  │ lessons/                │  │ tools/syncctl/     │
│   entry.sh             │  │   bash-fundamentals.md  │  │   syncctl (exe)    │
│   block/               │  │   custom_style.sh*      │  │   lib/*.sh         │
│     utils.sh           │  │   exercise/             │  │   tests/           │
│     layout.sh          │  │     *.sh                │  │                    │
│     theme.sh*          │  │                         │  │ Self-contained     │
│     renderer.sh        │  │ DEPENDS ON:             │  │ No external deps   │
│     status.sh          │  │   core (colors, tools)  │  │                    │
│   styles/              │  │   block engine          │  └────────────────────┘
│     block_style.sh     │  │                         │
│     symbols.sh         │  │                         │
│                        │  │                         │
│ tools/ai_block.sh      │  │                         │
│                        │  │                         │
│ DEPENDS ON:            │  │                         │
│   core (01-colors.sh,  │  │                         │
│   00.1-function-tools) │  │                         │
└────────────────────────┘  └─────────────────────────┘
```

---

## ⚠️ Cross-Dependencies to Resolve

| From | To | Issue |
|------|----|-------|
| `joe-block/block/theme.sh` | `01-colors.sh` | Engine → Core |
| `joe-block/block/theme.sh` | `00.1-function-tools.sh` | Engine → Core |
| `joe-block/block/theme.sh` | `lessons/custom_style.sh` | Engine → Lessons |
| `00-fm-loader.sh` | `lessons/exercise/01-exercise_joe.sh` | Core → Lessons |
| `02-aliases.sh` | `tools/merge.sh` | Core → Tools |

---

## Recommendations for Split

1. **Core** should export color functions (`c`, `rc`, `ctab`, `hline`) and tool helpers (`_pvar`, `_pfunc`) as a **public API** that other repos can `source`

2. **Block Engine** should accept color/style as parameters or source from a configurable `$SSOT_PATH`

3. **Lessons** should be standalone with `source` from core + engine at runtime

4. **Syncctl** is cleanest — fully self-contained, no changes needed
