# 🚀 JOE_ENV — Personal Command Center

> Cross-platform bash/zsh ecosystem for **Termux**, **WSL**, and **Git Bash**.
> Single entry point → auto-detect environment → load everything.

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/sitthawat035/bashscripts.git
cd bashscripts

# 2. Install (auto-detects Termux/WSL/Git Bash)
./bootstrap/setup.sh

# 3. Reload shell
source ~/.bashrc   # WSL / Git Bash
source ~/.zshrc    # Termux
```

---

## Architecture

### Directory Structure

```
bashscripts/
│
├── joe.sh                    ← 🎯 MAIN ENTRY POINT (source this)
│
├── bootstrap/
│   ├── 00-env.sh             ← Environment variables (SSOT)
│   └── setup.sh              ← Installer script
│
├── core/
│   ├── 01-colors.sh          ← Color engine V3 (c/cn/color/ctab/hline/rc)
│   ├── 02-aliases.sh         ← All shell aliases
│   ├── 3worlds.sh            ← SSH/transfer (tm/tw/wsl/push/pull)
│   ├── profiles.sh           ← AI profile switching (ai_profile/pf)
│   ├── theme.sh              ← Prompt customization (PROMPT_COMMAND)
│   └── .zsh-bash-compat.sh   ← Zsh/Bash compatibility layer
│
├── functions/
│   ├── 00-fm-loader.sh       ← File manager bootstrapper
│   ├── 00.1-function-tools.sh← Shared helpers (mth/math/backup)
│   ├── 02-systems.sh         ← System utils (kp/fpk/gpc/adb/scrcpy)
│   ├── 03-fpath.sh           ← Path functions (fn/ep/hop/sd/cdc)
│   ├── 04-openclaw.sh        ← OpenClaw integration
│   ├── 05-pathx.sh           ← Path explorer
│   ├── 05-project.sh         ← Project runners (opdb/opall/tsc)
│   ├── 07-wtf.sh             ← Diagnostic tool
│   ├── 08-nexus.sh           ← Nexus utilities
│   ├── 09-all_block_status.sh← Block status dashboard
│   ├── 10-ai.sh              ← AI helpers
│   ├── 11-bash-manager.sh    ← File Manager CLI (fm/xfm)
│   ├── 12-git.sh             ← Git helpers
│   └── tools.sh              ← Misc tools
│
├── plugins/
│   ├── block_engine/         ← Terminal block renderer
│   │   ├── entry.sh          ← Public API (m/dashboard/dashboard_array)
│   │   ├── block/            ← Internal modules
│   │   │   ├── utils.sh      ← Constants, helpers
│   │   │   ├── layout.sh     ← Layout engine
│   │   │   ├── theme.sh      ← Theme loader & color compiler
│   │   │   ├── renderer.sh   ← ASCII renderer
│   │   │   └── status.sh     ← Status data providers
│   │   └── styles/           ← Style definitions
│   │       └── block_style.sh
│   ├── syncctl/              ← Syncthing ownership controller
│   │   ├── syncctl           ← CLI entry (sourced by joe.sh)
│   │   ├── lib/              ← Submodules (api/config/state/lock/etc.)
│   │   └── tests/            ← Test fixtures
│   └── hermes/               ← Hermes AI integration
│       └── hermes.sh
│
├── modules/                  ← Optional helper tools
│   ├── ai_block.sh           ← AI block renderer
│   ├── color-chart.sh        ← Color chart display
│   ├── cli-cheatsheet.md     ← CLI cheat sheet
│   ├── patch_theme.sh        ← Theme patcher
│   └── wtf.sh                ← Legacy diagnostic
│
├── tools/                    ← Standalone executables (run, not source)
│   ├── safe-edit.sh          ← Pre-commit guard (ANSI/drift check)
│   ├── ssot-audit.sh         ← SSOT drift detector
│   ├── merge.sh              ← Tree/merge tools
│   ├── git-easy.sh           ← Git helpers
│   ├── agent-pre-commit.sh   ← Agent pre-commit hook
│   └── Fresh_termux_fullsetup_SSOT.sh ← Full Termux setup
│
├── profiles/                 ← Shell profile templates
│   ├── termux/.zshrc
│   └── git-bash/.bash_profile
│
├── lessons/                  ← Learning materials & exercises
│   ├── bash-fundamentals.md
│   └── exercise/
│
├── tests/
│   └── test_joe_env.sh       ← Test suite (bash + zsh)
│
├── AGENT.md                  ← AI agent instructions
├── DEPENDENCY_MAP.md         ← Dependency analysis
└── RESTRUCTURE_PLAN.md       ← Migration plan
```

---

## Path Variable System

JOE_ENV uses a **layered path system** with `JOE_ROOT` as the base:

| Variable | Value | Description |
|----------|-------|-------------|
| `JOE_ROOT` | `$HOME/bashscripts` | Repo root (auto-detected from `joe.sh` location) |
| `JOE_CORE` | `$JOE_ROOT/core` | Core modules |
| `JOE_FUNCTIONS` | `$JOE_ROOT/functions` | Function modules |
| `JOE_PLUGINS` | `$JOE_ROOT/plugins` | Plugin modules |
| `JOE_TOOLS` | `$JOE_ROOT/tools` | Standalone tools |

**Backward compatibility** (still set for legacy scripts):

| Variable | Alias For |
|----------|-----------|
| `SSOT` | `$JOE_ROOT` |
| `SCRIPTS_PATH` | `$JOE_ROOT` |

### Usage in Scripts

```bash
# New style (recommended)
source "$JOE_CORE/01-colors.sh"
source "$JOE_PLUGINS/block_engine/entry.sh"
source "$JOE_PLUGINS/syncctl/syncctl"

# Backward compat (still works)
source "$SSOT/core/01-colors.sh"
source "$SCRIPTS_PATH/plugins/block_engine/entry.sh"
```

---

## Environment Detection (JOE_ENV)

`joe.sh` auto-detects your environment on startup:

| `JOE_ENV` | Platform | Shell | Notes |
|-----------|----------|-------|-------|
| `TERMUX` | Android (Termux) | zsh | `/data/data/com.termux` detected |
| `MUMU` | MuMuPlayer emulator | zsh | Termux on Android emulator |
| `WSL` | Windows Subsystem for Linux | bash | `microsoft` in `/proc/version` |
| `GIT-BASH` | Git Bash on Windows | bash | `$OSTYPE == msys/cygwin` |

### Per-Environment Paths

```
TERMUX/MUMU:                         WSL:
  $HOME = /data/data/com.termux/...    $HOME = /home/usercivenz
  SSOT   = $HOME/bashscripts           SSOT   = $HOME/bashscripts
  hpc    = (not set)                   hpc    = /mnt/c/Users/User
  hwsl   = (not set)                   hwsl   = $HOME

GIT-BASH:
  $HOME = /c/Users/User
  SSOT   = $HOME/bashscripts
  hpc    = $HOME
  hwsl   = //wsl.localhost/Ubuntu/home/usercivenz
```

---

## Boot Sequence

```
~/.bashrc or ~/.zshrc
  └─ source joe.sh                    ← ONLY entry point
       │
       ├─ Step 0: Detect JOE_ENV      ← TERMUX | MUMU | WSL | GIT-BASH
       ├─ Step 1: Set SSOT, hpc, hwsl, DASHBOARD_DIR
       ├─ Step 1.5: CRLF self-heal    ← auto-fix Windows line endings
       ├─ Step 2: Set JOE_ROOT/JOE_CORE/JOE_PLUGINS/JOE_TOOLS
       │
       ├─ Source bootstrap/00-env.sh  ← env vars (HERMES_DIR, NODE_*, etc.)
       ├─ Source core/01-colors.sh    ← color engine (c/cn/color/ctab/hline)
       ├─ Auto-start sshd & ssh-agent
       ├─ Source core/3worlds.sh      ← SSH (tm/tw/wsl/push/pull)
       ├─ Source core/02-aliases.sh   ← aliases (cls/h/reload/merge/etc.)
       ├─ Source core/profiles.sh     ← ai_profile/pf
       ├─ Source core/theme.sh        ← prompt & PROMPT_COMMAND
       │
       ├─ Source functions/*.sh       ← ALL function modules (glob)
       │   └─ plugins/block_engine/entry.sh  ← block engine (m/dashboard)
       ├─ Source plugins/syncctl/syncctl     ← syncthing controller
       │
       └─ Startup tasks              ← syncthing_auto, rc_del
```

**Critical ordering:**
- `00-env.sh` must load BEFORE functions (provides `NODE_*`, `ST_KEY_*`, etc.)
- `01-colors.sh` must load BEFORE anything that prints colors
- `3worlds.sh` depends on `00-env.sh` (uses `NODE_*` vars)

---

## Key Features

### 🎨 Color Engine V3 (`core/01-colors.sh`)

```bash
# Print with color (256-color palette)
c  202 b "bold orange"          # no newline (concatenable)
cn 46  b "green bold + newline" # with newline

# Style modifiers: b=bold, d=dim, i=italic, u=underline
c 196 bi "bold+italic red"

# Table & line helpers
ctab 4 "label" "value"          # formatted table row
hline 60                         # horizontal line

# Random palette
rc  b "random color bold"       # random from palette
rc1 b "random from palette 1"
```

**V3 rules:**
- ❌ NO inline ANSI escapes (`\e[38;5;Nm`) outside `01-colors.sh`
- ❌ NO legacy color vars (`$RED`, `$GREEN`, `$BOLD`)
- ✅ Use `c()/cn()/color()` from `01-colors.sh`
- ✅ Use `$(_b)/$(_d)/$(_i)/$(_u)` for raw escapes

### 🌍 Multi-World SSH (`core/3worlds.sh`)

```bash
tm          # SSH to Termux
tw          # SSH to Windows (Git Bash)
wsl         # SSH to WSL
push        # Push files to Termux
update      # Update Termux packages
cptw file   # Copy file: Windows → Termux
cpw2t file  # Same as cptw
```

### 📊 Block Engine (`plugins/block_engine/`)

```bash
# Render a status block
m 50                  # style 50, offset 50 columns
m_random              # random style
echo "row1\nrow2" | dashboard    # pipe rows

# Status providers
status_new            # system status block
op_profile            # OpenClaw profile block
```

### 🔄 Syncthing Controller (`plugins/syncctl/`)

```bash
syncctl status        # show cluster status
syncctl doctor        # diagnose issues
syncctl handover      # transfer master ownership
syncctl pause         # pause sync
syncctl resume        # resume sync
```

---

## SSOT (Single Source of Truth) Architecture

Each domain has ONE canonical file:

| Domain | SSOT File | Owns |
|--------|-----------|------|
| Environment | `bootstrap/00-env.sh` | All env vars, paths, keys |
| Colors | `core/01-colors.sh` | Color engine, palette |
| SSH/Transfer | `core/3worlds.sh` | `tm/tw/wsl/push` |
| Aliases | `core/02-aliases.sh` | All aliases |
| Block Engine | `plugins/block_engine/entry.sh` | `m/dashboard` |
| Syncthing | `plugins/syncctl/syncctl` | `syncctl` CLI |

**Rule:** Never redefine a variable/function from another SSOT file.
Reference it instead: `source "$JOE_CORE/01-colors.sh"` then call `cn`.

---

## Testing

```bash
# Run full test suite (55 tests)
bash tests/test_joe_env.sh     # bash
zsh  tests/test_joe_env.sh     # zsh compatibility

# Tests cover:
# - Directory structure (all dirs exist)
# - Core files (all SSOT files exist)
# - Plugin files (block_engine, syncctl, hermes)
# - Old path removal (no legacy files in root)
# - Source path consistency (all files use JOE_* paths)
# - No hardcoded /home/usercivenz
# - Cross-dependency resolution
# - Bash & zsh compatibility
```

---

## Cross-Platform Compatibility

| Feature | Termux | WSL | Git Bash |
|---------|--------|-----|----------|
| Shell | zsh | bash | bash |
| Color Engine | ✅ | ✅ | ✅ |
| SSH/Tmux | ✅ | ✅ | ⚠️ Limited |
| Block Engine | ✅ | ✅ | ✅ |
| Syncthing | ✅ | ✅ | ⚠️ Limited |
| File Manager | ✅ | ✅ | ✅ |
| CRLF Auto-fix | ✅ | ✅ | ✅ |

---

## Safety Tools

### `safe-edit.sh` — Pre-commit Guard
```bash
bash tools/safe-edit.sh <file>    # Check a file
# Blocks: inline ANSI, V2 color vars, hardcoded IPs/keys
```

### `ssot-audit.sh` — SSOT Drift Detector
```bash
bash tools/ssot-audit.sh          # Audit entire repo
# Checks: color SSOT, env SSOT, load order, syntax
```

---

## License

Personal project — not for distribution.
