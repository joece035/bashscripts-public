# Migration Plan — JOE_ENV Reorganization

> Target: Reorganize `bashscripts/` into the JOE_ENV structure
> Created: 2026-08-09

---

## Target Structure

```
bashscripts/ (becomes JOE_ENV/)
│
├── bootstrap/
│   ├── setup.sh                    ← NEW: main installer
│   ├── 00-env.sh                   ← MOVE: root/00-env.sh
│   └── README.md
│
├── core/
│   ├── 01-colors.sh                ← MOVE: root/01-colors.sh
│   ├── 02-aliases.sh               ← MOVE: root/02-aliases.sh
│   ├── 3worlds.sh                  ← MOVE: root/3worlds.sh
│   ├── profiles.sh                 ← MOVE: root/profiles.sh
│   ├── theme.sh                    ← MOVE: root/theme.sh
│   └── .zsh-bash-compat.sh         ← MOVE: root/.zsh-bash-compat.sh
│
├── functions/
│   ├── 00-fm-loader.sh             ← STAY (update paths)
│   ├── 00.1-function-tools.sh      ← STAY (update paths)
│   ├── 02-systems.sh               ← STAY
│   ├── 03-fpath.sh                 ← STAY (update paths)
│   ├── 04-openclaw.sh              ← STAY
│   ├── 05-pathx.sh                 ← STAY
│   ├── 05-project.sh               ← STAY
│   ├── 07-wtf.sh                   ← STAY
│   ├── 08-nexus.sh                 ← STAY
│   ├── 09-all_block_status.sh      ← STAY
│   ├── 10-ai.sh                    ← STAY
│   ├── 11-bash-manager.sh          ← STAY (update paths)
│   ├── 12-git.sh                   ← STAY
│   └── tools.sh                    ← STAY
│
├── plugins/
│   ├── block_engine/               ← MOVE: functions/joe-block/
│   │   ├── entry.sh                ← UPDATE paths
│   │   ├── README.md
│   │   ├── block/
│   │   │   ├── layout.sh
│   │   │   ├── renderer.sh
│   │   │   ├── status.sh
│   │   │   ├── theme.sh            ← UPDATE paths (cross-dep)
│   │   │   └── utils.sh
│   │   └── styles/
│   │       ├── block_style.sh
│   │       └── symbols.sh
│   ├── syncctl/                    ← MOVE: tools/syncctl/
│   │   ├── syncctl
│   │   ├── README.md
│   │   ├── lib/
│   │   └── tests/
│   └── hermes/                     ← MOVE: tools/hermes.sh (new dir)
│       └── hermes.sh
│
├── modules/                        ← Helper tools (optional load)
│   ├── ai_block.sh                 ← MOVE: tools/ai_block.sh
│   ├── color_chart.sh              ← MOVE: tools/color_chart.sh
│   ├── cli_cheatsheet.md           ← MOVE: tools/cli-cheatsheet.md
│   ├── patch_theme.sh              ← MOVE: tools/patch_theme.sh
│   └── wtf.sh                      ← MOVE: tools/wtf.sh
│
├── tools/                          ← Executable commands (run, not source)
│   ├── merge.sh                    ← MOVE: tools/merge.sh
│   ├── safe_edit.sh                ← MOVE: tools/safe-edit.sh
│   ├── ssot_audit.sh               ← MOVE: tools/ssot-audit.sh
│   ├── git_easy.sh                 ← MOVE: tools/git-easy.sh
│   └── Fresh_termux_fullsetup_SSOT.sh ← MOVE: tools/Fresh_...sh
│
├── profiles/
│   ├── termux/
│   │   └── .zshrc                  ← MOVE: tools/zshrc_termux.zsh
│   ├── wsl/
│   │   └── .bashrc                 ← NEW or MOVE
│   └── git-bash/
│       └── .bash_profile           ← MOVE: tools/.zshrc (rename)
│
├── lessons/
│   ├── bash-fundamentals.md        ← MOVE: root/lessons/bash-fundamentals.md
│   ├── custom_style.sh             ← MOVE: root/lessons/custom_style.sh
│   └── exercise/
│       ├── 00-exercise_color_config.sh
│       ├── 01-exercise_joe.sh      ← UPDATE paths
│       ├── 02-exercise_block_style.sh
│       ├── 03-exercise _status.sh
│       ├── test_case_w.sh
│       └── test_case_w_HINT.sh
│
├── joe.sh                          ← STAY (update all source paths)
├── ble-test.sh                     ← STAY
├── AGENT.md                        ← STAY
├── DEPENDENCY_MAP.md               ← STAY
├── RESTRUCTURE_PLAN.md             ← THIS FILE
├── .editorconfig
├── .gitattributes
├── .gitignore
├── .github/
│   ├── hooks/pre-commit.json
│   ├── instructions/joe-block.instructions.md  ← UPDATE refs
│   ├── prompts/handover-report.prompt.md
│   └── skills/syncctl/SKILL.md     ← UPDATE refs
└── ผังโครงสร้างโปรเจค.txt
```

---

## ⚠️ Cross-Dependencies to Resolve

| File | Currently Sources | New Path | Action |
|------|------------------|----------|--------|
| `joe-block/block/theme.sh` | `${_BLOCK_ROOT}/01-colors.sh` | `core/01-colors.sh` | Update variable |
| `joe-block/block/theme.sh` | `${_BLOCK_ROOT}/functions/00.1-function-tools.sh` | `functions/00.1-function-tools.sh` | Update variable |
| `joe-block/block/theme.sh` | `${_BLOCK_ROOT}/lessons/custom_style.sh` | `lessons/custom_style.sh` | Update variable |
| `00-fm-loader.sh` | `/home/usercivenz/bashscripts/lessons/...` (HARDCODED) | `lessons/exercise/01-exercise_joe.sh` | Fix hardcoded path |
| `00-fm-loader.sh` | `/home/usercivenz/bashscripts/tools/hermes.sh` (HARDCODED) | `plugins/hermes/hermes.sh` | Fix hardcoded path |
| `02-aliases.sh` | `$SSOT/tools/merge.sh` | `tools/merge.sh` | Update variable |

---

## Path Variable Changes

### Current Variables (6 different roots)
```bash
$SCRIPTS_PATH    # joe.sh — repo root
$SSOT            # 00-env.sh — same root
$_ssot           # 00.1-function-tools.sh — same root
$_BLOCK_ROOT     # joe-block/theme.sh — same root
$_BS_ROOT        # lessons/exercise/ — same root
$_D              # joe-block/entry.sh — functions/joe-block/block/
$COLOR_PATH      # 00-env.sh — functions/joe-block/styles/
```

### New Variables (target)
```bash
$JOE_ROOT        # Single root variable
$JOE_CORE        # $JOE_ROOT/core
$JOE_FUNCTIONS   # $JOE_ROOT/functions
$JOE_PLUGINS     # $JOE_ROOT/plugins
$JOE_TOOLS       # $JOE_ROOT/tools
```

### Migration in `00-env.sh` (bootstrap)
```bash
# OLD
SCRIPTS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSOT="$SCRIPTS_PATH"
COLOR_PATH="$SCRIPTS_PATH/functions/joe-block/styles"

# NEW
JOE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # up one from bootstrap/
JOE_CORE="$JOE_ROOT/core"
JOE_FUNCTIONS="$JOE_ROOT/functions"
JOE_PLUGINS="$JOE_ROOT/plugins"
JOE_TOOLS="$JOE_ROOT/tools"
SCRIPTS_PATH="$JOE_ROOT"  # backward compat
SSOT="$JOE_ROOT"           # backward compat
```

---

## File-by-File Path Updates

### 1. `joe.sh` — Main entry point

```bash
# OLD
source "$SCRIPTS_PATH/00-env.sh"
source "$SCRIPTS_PATH/01-colors.sh"
source "$SCRIPTS_PATH/3worlds.sh"
source "$SCRIPTS_PATH/02-aliases.sh"
source "$SCRIPTS_PATH/profiles.sh"
source "$COLOR_PATH/theme.sh"
source "$SCRIPTS_PATH/functions/joe-block/entry.sh"
source "$SCRIPTS_PATH/tools/syncctl/syncctl"

# NEW
source "$JOE_ROOT/bootstrap/00-env.sh"        # bootstrap ย้ายไป
source "$JOE_CORE/01-colors.sh"
source "$JOE_CORE/3worlds.sh"
source "$JOE_CORE/02-aliases.sh"
source "$JOE_CORE/profiles.sh"
source "$JOE_PLUGINS/block_engine/styles/theme.sh"  # root theme → block_engine styles
source "$JOE_PLUGINS/block_engine/entry.sh"
source "$JOE_PLUGINS/syncctl/syncctl"
```

### 2. `functions/00-fm-loader.sh` — 6 path updates

```bash
# Line 12
source "$SSOT/functions/11-bash-manager.sh"
→ source "$JOE_FUNCTIONS/11-bash-manager.sh"

# Line 83
source "$SSOT/functions/joe-block/styles/block_style.sh"
→ source "$JOE_PLUGINS/block_engine/styles/block_style.sh"

# Line 88
source $SSOT/functions/joe-block/entry.sh
→ source $JOE_PLUGINS/block_engine/entry.sh

# Line 114 (HARDCODED!)
source /home/usercivenz/bashscripts/lessons/exercise/01-exercise_joe.sh
→ source "$JOE_ROOT/lessons/exercise/01-exercise_joe.sh"

# Line 120
source "$SSOT/tools/hermes.sh"
→ source "$JOE_PLUGINS/hermes/hermes.sh"

# Line 122 (HARDCODED!)
source /home/usercivenz/bashscripts/tools/hermes.sh
→ source "$JOE_PLUGINS/hermes/hermes.sh"
```

### 3. `functions/00.1-function-tools.sh` — 2 path updates

```bash
# Line 885
source $SSOT/tools/hermes.sh
→ source $JOE_PLUGINS/hermes/hermes.sh

# Line 958
source "$_ssot/tools/syncctl/syncctl"
→ source "$JOE_PLUGINS/syncctl/syncctl"
```

### 4. `functions/joe-block/entry.sh` — 5 path updates

```bash
# _D variable definition
_D="$(dirname "$0")/block"
→ _D="$(dirname "$0")/block"  # stays same (relative)

# These 5 lines use ${_D} which is relative — NO CHANGE needed
source "${_D}/utils.sh"
source "${_D}/layout.sh"
source "${_D}/theme.sh"
source "${_D}/renderer.sh"
source "${_D}/status.sh"
```

### 5. `functions/joe-block/block/theme.sh` — 4 path updates

```bash
# _BLOCK_ROOT definition needs update
_BLOCK_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
→ _BLOCK_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"  # adjust depth

# Line 77
source "${_BLOCK_ROOT}/01-colors.sh"
→ source "${_BLOCK_ROOT}/core/01-colors.sh"

# Line 82
source "${_BLOCK_ROOT}/functions/00.1-function-tools.sh"
→ source "${_BLOCK_ROOT}/functions/00.1-function-tools.sh"  # stays same

# Line 86
source "${_BLOCK_ROOT}/functions/joe-block/styles/block_style.sh"
→ source "${_BLOCK_ROOT}/plugins/block_engine/styles/block_style.sh"

# Line 88
source "${_BLOCK_ROOT}/lessons/custom_style.sh"
→ source "${_BLOCK_ROOT}/lessons/custom_style.sh"  # stays same
```

### 6. `02-aliases.sh` — 1 path update

```bash
# Line 118
alias merge='source $SSOT/tools/merge.sh && merge_functions'
→ alias merge='source $JOE_ROOT/tools/merge.sh && merge_functions'
```

### 7. `tools/ai_block.sh` — 1 path update

```bash
# Line 96
source "$SSOT/functions/joe-block/entry.sh"
→ source "$JOE_PLUGINS/block_engine/entry.sh"
```

### 8. `lessons/exercise/01-exercise_joe.sh` — 2 path updates

```bash
# _BS_ROOT definition
_BS_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
→ _BS_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"  # stays same (relative)

# Line 21
source "${_BS_ROOT}/00-colors.sh"
→ source "${_BS_ROOT}/core/01-colors.sh"  # 00 → 01, add core/

# Line 22
source "${_BS_ROOT}/functions/00.1-function-tools.sh"
→ source "${_BS_ROOT}/functions/00.1-function-tools.sh"  # stays same
```

### 9. `functions/11-bash-manager.sh` — 0 active changes

Only comments reference paths. No active `source` commands.

### 10. `functions/03-fpath.sh` — 1 path update

```bash
# Uses _jb variable pointing to joe-block
source "$jb"
→ source "$JOE_PLUGINS/block_engine/entry.sh"
```

---

## Execute Plan

### Step 1: Create new directories
```bash
cd ~/bashscripts
mkdir -p bootstrap core plugins/block_engine plugins/syncctl plugins/hermes modules tools profiles/termux profiles/wsl profiles/git-bash lessons
```

### Step 2: Move files
```bash
# Core
mv 00-env.sh bootstrap/
mv 01-colors.sh core/
mv 02-aliases.sh core/
mv 3worlds.sh core/
mv profiles.sh core/
mv theme.sh core/
mv .zsh-bash-compat.sh core/

# Plugins
mv functions/joe-block plugins/block_engine
mv tools/syncctl plugins/syncctl
mkdir plugins/hermes && mv tools/hermes.sh plugins/hermes/

# Modules
mv tools/ai_block.sh modules/
mv tools/color_chart.sh modules/
mv tools/cli-cheatsheet.md modules/
mv tools/patch_theme.sh modules/
mv tools/wtf.sh modules/

# Tools (executable)
mv tools/merge.sh tools/
mv tools/safe-edit.sh tools/
mv tools/ssot-audit.sh tools/
mv tools/git-easy.sh tools/
mv tools/Fresh_termux_fullsetup_SSOT.sh tools/

# Profiles
mv tools/zshrc_termux.zsh profiles/termux/.zshrc
mv tools/.zshrc profiles/git-bash/.bash_profile

# Lessons (already in place)
# lessons/ stays as-is

# Clean up
rm tools/syncctl.zip 2>/dev/null
rm tools/test_glob.zsh 2>/dev/null
```

### Step 3: Update paths in source files
*(Run sed commands from Section "File-by-File Path Updates" above)*

### Step 4: Create bootstrap/setup.sh
```bash
#!/bin/bash
# JOE_ENV Bootstrap Script
# Usage: git clone <repo> && cd JOE_ENV && ./bootstrap/setup.sh

JOE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "🔧 Installing JOE_ENV..."

# Source core
source "$JOE_ROOT/bootstrap/00-env.sh"
source "$JOE_ROOT/core/01-colors.sh"

# Add to shell profile
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == */zsh ]] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "JOE_ENV" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# JOE_ENV" >> "$SHELL_RC"
    echo "source '$JOE_ROOT/joe.sh'" >> "$SHELL_RC"
    echo "✅ Added to $SHELL_RC"
fi

echo "✅ JOE_ENV installed! Run 'source $SHELL_RC' or open new terminal."
```

### Step 5: Test
```bash
source joe.sh  # Should work with new paths
joe            # Test block rendering
c red "test"   # Test color system
```

### Step 6: Commit
```bash
git add -A
git commit -m "refactor: reorganize into JOE_ENV structure

- bootstrap/: setup script, env detection
- core/: shell infrastructure (colors, aliases, themes)
- functions/: function library
- plugins/: block_engine, syncctl, hermes
- modules/: optional helpers
- tools/: executable commands
- profiles/: termux, wsl, git-bash
- lessons/: learning materials"
```

---

## Verification Checklist

- [ ] `source joe.sh` works
- [ ] `joe` command renders blocks
- [ ] `c red "test"` shows color
- [ ] `ctab` shows color table
- [ ] `syncctl doctor` works
- [ ] `00-fm-loader.sh` loads without errors
- [ ] No "command not found" for any function
- [ ] Lessons exercises still work
