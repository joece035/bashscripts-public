---
name: bashscripts-agent
description: Agent for working with Joe's Bashscripts ecosystem. Must follow SSOT architecture rules strictly.
tools: Read, Grep, Glob, Bash
---

# 🏗️ Bashscripts Agent — JOE_ENV Architecture Rules

> **⚠️ MANDATORY: Every agent working in this repo MUST follow these rules. No exceptions.**

## 1. Project Overview

**Purpose:** Joe's Personal Command Center — a cross-platform bash/zsh scripts ecosystem that works on **Termux, WSL, and Git Bash**. It provides environment detection, SSH tunneling between devices, file management, and a unified CLI experience.

**Key Design Principle:** **Single Source of Truth (SSOT)** — each domain has ONE canonical file that owns its variables/functions. All other files reference (never redefine) these definitions.

**Path System:** All files use `JOE_ROOT`-based paths (`$JOE_CORE`, `$JOE_FUNCTIONS`, `$JOE_PLUGINS`, `$JOE_TOOLS`). Legacy aliases `SSOT` and `SCRIPTS_PATH` are kept for backward compat only.

## 📚 Related Instruction Files

| File | Scope | When to Load |
|------|-------|--------------|
| `.github/instructions/joe-block.instructions.md` | Block Engine (UI rendering) | When working with `functions/joe-block/` |
| `.github/skills/syncctl/SKILL.md` | Syncthing cluster management | When using `syncctl` commands |
| `.github/prompts/handover-report.prompt.md` | Handover report generation | When generating handover reports |

## 2. Architecture Overview (JOE_ENV + SSOT)

This repo uses a **JOE_ENV directory structure** with strict SSOT rules. Each file is the **canonical source** for its domain. When creating or modifying scripts, you **MUST** reference existing variables/functions via `JOE_*` paths — never redefine or hardcode them.

### Directory Structure

```
bashscripts/
├── joe.sh                    ← MAIN ENTRY POINT
├── bootstrap/
│   ├── 00-env.sh             ← Environment variables (SSOT)
│   └── setup.sh              ← Installer
├── core/
│   ├── 01-colors.sh          ← Color engine (SSOT)
│   ├── 02-aliases.sh         ← All aliases (SSOT)
│   ├── 3worlds.sh            ← SSH/transfer (SSOT)
│   ├── profiles.sh           ← AI profile switching
│   ├── theme.sh              ← Prompt customization
│   └── .zsh-bash-compat.sh   ← Zsh/Bash compat
├── functions/                ← Function modules (loaded by joe.sh glob)
├── plugins/
│   ├── block_engine/         ← Terminal block renderer
│   ├── syncctl/              ← Syncthing controller
│   └── hermes/               ← Hermes AI
├── modules/                  ← Optional helpers
├── tools/                    ← Standalone executables
├── profiles/                 ← Shell profile templates
└── lessons/                  ← Learning materials
```

### Path Variable System

| Variable | Value | Use |
|----------|-------|-----|
| `JOE_ROOT` | `$HOME/bashscripts` | Repo root |
| `JOE_CORE` | `$JOE_ROOT/core` | Core modules |
| `JOE_FUNCTIONS` | `$JOE_ROOT/functions` | Function modules |
| `JOE_PLUGINS` | `$JOE_ROOT/plugins` | Plugin modules |
| `JOE_TOOLS` | `$JOE_ROOT/tools` | Standalone tools |
| `SSOT` | `$JOE_ROOT` | Backward compat alias |
| `SCRIPTS_PATH` | `$JOE_ROOT` | Backward compat alias |

### Load Order (set by `joe.sh` — verified 2026-08-09)

> **⚠️ This is the AUTHORITATIVE order.** When adding new modules, integrate
> into the correct stage below. Do NOT add `source` calls outside of `joe.sh`.

```
~/.bashrc or ~/.zshrc
  └─ source joe.sh                          [BOOSTER — only entry point]
       ├─ Step 0: detect JOE_ENV            (TERMUX | MUMU | WSL | GIT-BASH)
       ├─ Step 1: set SSOT, SCRIPTS_PATH, hpc/htm/hwsl, DASHBOARD_DIR
       ├─ Step 1.5: CRLF self-heal          (auto-fix Windows line endings)
       ├─ Step 2: set JOE_ROOT/JOE_CORE/JOE_PLUGINS/JOE_TOOLS
       │
       ├─ source bootstrap/00-env.sh        ← env vars, paths, keys
       ├─ source core/01-colors.sh          ← c()/cn()/color(), ctab, hline, rc()
       ├─ auto-start sshd & ssh-agent
       ├─ source core/3worlds.sh            ← tm/tw/wsl/push/pull
       ├─ source core/02-aliases.sh         ← cls, h, reload, etc.
       ├─ source core/profiles.sh           ← ai_profile() + alias pf
       ├─ source core/theme.sh              ← prompt & PROMPT_COMMAND
       │
       ├─ source functions/*.sh             ← glob: all function modules
       │   └─ source plugins/block_engine/entry.sh  ← m/dashboard
       ├─ source plugins/syncctl/syncctl    ← syncthing controller
       │
       └─ startup tasks                     ← syncthing_auto, rc_del
```

**Critical invariants:**
- `bootstrap/00-env.sh` is sourced BEFORE any `functions/*.sh` — every function
  module can safely read `$OC_KEY_*`, `$WINDOWS_IP`, `$ST_KEY_*`, etc.
- `core/01-colors.sh` is sourced BEFORE any function module that prints
  colorized output (e.g. `cn 202 b "msg"`).
- Functions in `functions/*.sh` may source each other freely (alphabetical
  loop order: 00-fm-loader → 00.1-function-tools → 02-systems → ...).
- `ai_profile()` is the **only** function that mutates `OPENCODE_*` vars
  at runtime. Never reassign these from other files.
- Path variables: `JOE_ROOT` is the canonical name (set in joe.sh Step 2),
  `SSOT`/`SCRIPTS_PATH` are aliases kept for backward compat.

### SSOT File Map (อัปเดต 2026-08-09 — JOE_ENV restructure)

> **JOE_ENV มีค่าเดียวเท่านั้น: `TERMUX | MUMU | WSL | GIT-BASH`**
> All files now use `JOE_ROOT`-based paths (`$JOE_CORE`, `$JOE_PLUGINS`, etc.)

| File | Domain | What it owns |
|------|--------|-------------|
| `joe.sh` | Boot | `JOE_ENV` (Step 0 detect), `JOE_ROOT/JOE_CORE/JOE_PLUGINS/JOE_TOOLS`, `hpc/htm/hwsl`, `SSOT`, `SCRIPTS_PATH`, `DASHBOARD_DIR`, `pp()`, `ai_profile()` |
| `bootstrap/00-env.sh` | Environment | `HERMES_DIR`, `PYTHON_VENV`, `SDCARD_PATH`, `oppc`, `dpc`, `hmp`, Node Registry (`NODE_*`), compat layer (`ST_KEY_*`, `ST_PORT_*`, `URL_*`), OpenCode keys (`$OC_KEY_*`), crypto addresses, `BACKUP_DIR` |
| `core/01-colors.sh` | Colors | `c()` (no newline), `cn()` (newline), `color()` (legacy), `_c/_r/_b/_d/_i/_u` (escape), `ctab()` (table), `hline()` (divider), `rc()`, palette |
| `core/02-aliases.sh` | Aliases | ALL aliases (`cls`, `h`, `reload`, `merge`, `fm`, etc.) — sources `$JOE_TOOLS/merge.sh` |
| `core/3worlds.sh` | SSH/Transfer | `tm()`, `tw()`, `wsl()`, `push()`, `update()`, `cptw/cpw2t`, `_ssh_node`, `_rsync_to/_rsync_from`, Syncthing auto |
| `core/profiles.sh` | AI Profile | `ai_profile()` + alias `pf`, `current_stats()` + alias `stc`, `clear_cache` |
| `core/theme.sh` | Prompt | `_git_prompt()`, `_exit_status()`, `_set_prompt()`, `PROMPT_COMMAND` |
| `functions/00-fm-loader.sh` | FM Loader | `scripts_sync()`, `tskg()`, `dbsync()`, learn/block/tools bootstrapping |
| `functions/00.1-function-tools.sh` | Function Tools | `agent_md()`, backup helpers, `mth()`, math helpers — uses `$JOE_PLUGINS/syncctl/syncctl`, `$JOE_PLUGINS/hermes/hermes.sh` |
| `functions/03-fpath.sh` | Function Paths | `FUNC_DIR=$JOE_FUNCTIONS`, `fn()`, `ep()`, `hop()`, `sd()`, `cdc()` |
| `functions/11-bash-manager.sh` | File Manager | `fm` (ls/cp/mv/tree/ssh/push/pull...), `xfm` (cross-machine) — uses `$JOE_CORE/01-colors.sh`, `$JOE_ROOT/bootstrap/00-env.sh` |
| `plugins/block_engine/entry.sh` | Block Engine | `m()` (style selector), `dashboard()`, `dashboard_array()`, `_blk_source_modules()` |
| `plugins/block_engine/block/theme.sh` | Block Theme | `_load_theme()`, `_apply_color_to()` — uses `$JOE_CORE/01-colors.sh`, `$JOE_FUNCTIONS/00.1-function-tools.sh`, `$JOE_PLUGINS/block_engine/styles/block_style.sh` |
| `plugins/syncctl/syncctl` | Syncthing | `cmd_*()` dispatch, sourced by joe.sh — uses `$JOE_ROOT/bootstrap/00-env.sh`, `$JOE_CORE/01-colors.sh` |
| `tools/safe-edit.sh` | Pre-commit Guard | V4-aware: blocks inline ANSI, V2 vars, hardcoded IPs/keys — uses `$JOE_CORE/01-colors.sh`, `$JOE_ROOT/bootstrap/00-env.sh` |
| `tools/ssot-audit.sh` | SSOT Auditor | Detects drift, ANSI, syntax — uses `$ROOT/core/01-colors.sh`, `$ROOT/bootstrap/00-env.sh` |

> **⚠️ SYNCTHING CAVEAT:** `~/bashscripts` is synced via Syncthing across devices.
> After editing files, verify: `bash -n <file>` and check test suite passes.

## 2. ❌ FORBIDDEN Patterns (NEVER do this)

### ❌ Never use deleted color variables ($RED, $NC, $RESET, $PURPLE, etc.)
```bash
# WRONG — these variables are GONE in V3
echo -e "${RED}error${NC}"
echo -e "${LBLUE}info${RESET}"
echo -e "${PURPLE}text"        # never existed

# CORRECT — V3 has NO color variables. Use inline or helpers.
echo -e "\e[38;5;196merror\e[0m"
c 33 b "info"
```

### ❌ V4: Never hardcode ANY ANSI escape outside 01-colors.sh
```bash
# WRONG — inline 256-color outside 01-colors.sh is BANNED (V4, 2026-08-03)
echo -e "\e[38;5;196merror\e[0m"        # ❌ inline escape — drift risk
printf "\e[1;38;5;82mBold green\e[0m\n" # ❌
cat <<EOF
\e[1mEXAMPLES\e[0m                      # ❌ even in heredoc
\e[38;5;244m# comment\e[0m              # ❌
EOF
local _R_OK="\e[38;5;46m"               # ❌ local color var — invented
printf "${_R_BOLD}foo${_R_RESET}\n"     # ❌

# CORRECT — V4 mandatory: use helper from 01-colors.sh
cn 196 b "error"                        # 256-color + bold + newline
c 196 b "error"                         # same, no newline (chain)
color r b "error"                       # short name + bold (legacy)
color 196 b "error"                     # 256 number + bold
rc b "error"                            # random palette
```

**Rule of thumb:** The ONLY file allowed to contain raw `\e[` or `\033[`
is `01-colors.sh`. Everything else MUST go through `c()` / `cn()` /
`color()` / `ctab()` / `hline()` / `rc()` / `rc1()` / `rc2()`.

Enforcement: `tools/safe-edit.sh` + `tools/ssot-audit.sh` will FAIL any
file with inline ANSI outside `01-colors.sh`.

### ✅ Color System V3/V4 Quick Reference

| Function | Description | Example |
|----------|-------------|---------|
| `c <color> [style] <text>` | Print colored text (no newline) | `c 46 b "ON "` |
| `cn <color> [style] <text>` | Print colored text + newline | `cn 208 "WARN"` |
| `color <name\|num> [style] <text>` | Legacy helper (has newline) | `color r b "error"` |
| `ctab <label> <value>` | Print labeled table row | `ctab "Status" "OK"` |
| `hline <char> <width>` | Print horizontal line | `hline "-" 50` |
| `rc [style] <text>` | Random palette color | `rc b "info"` |
| `_c <num>` | Raw 256-color escape (for chaining) | `echo -e "$(_c 208)text$(_r)"` |
| `_b` / `_d` / `_i` / `_u` | Bold / dim / italic / underline escapes | `echo -e "$(_b)bold$(_r)"` |

### ❌ Never hardcode paths or IPs
```bash
# WRONG — these already exist in 00-env.sh
WINDOWS_IP="100.69.181.45"
TERMUX_IP="100.110.26.16"
DASHBOARD_DIR="$HOME/dashboard"
SCRIPTS_PATH="$HOME/bashscripts"
```

### ❌ Never hardcode environment detection
```bash
# WRONG — joe.sh already handles this
if [[ -d "/data/data/com.termux" ]]; then
    JOE_ENV="TERMUX"
fi
```

### ❌ Never create new env vars that overlap existing ones
```bash
# WRONG — $oppc already exists in 00-env.sh
MY_OPENCLAW_PATH="$hpc/openclaw"

# WRONG — $DASHBOARD_DIR already exists
MY_DASH="$HOME/dashboard"
```

### ❌ Never redefine existing functions
```bash
# WRONG — kp() already exists in functions/02-systems.sh
kill_port() { lsof -t -i:$1 | xargs kill -9; }
```

### ✅ Use SSOT environment variables
```bash
# CORRECT — reference variables from 00-env.sh
cd "$DASHBOARD_DIR"
ssh -p "$TERMUX_PORT" "$TERMUX_USER@$TERMUX_IP"
source "$PYTHON_VENV"
```

### ✅ Use SSOT path variables
```bash
# CORRECT — use $SCRIPTS_PATH for referencing this repo
source "$SCRIPTS_PATH/functions/02-systems.sh"

# CORRECT — use $oppc, $dtpc, etc. for navigation
cd "$oppc"
```

### ✅ Use JOE_ENV for environment branching
```bash
# CORRECT — use the detected JOE_ENV variable
if [[ "$JOE_ENV" == "TERMUX" ]]; then
    # Termux-specific logic
elif [[ "$JOE_ENV" == "WSL" ]]; then
    # WSL-specific logic
fi
```

### ✅ Add new functions to the correct module file
```bash
# New system utility? → functions/02-systems.sh
# New project runner? → functions/05-project.sh
# New OpenClaw function? → functions/04-openclaw.sh
# New SSH/transfer? → 3worlds.sh
```

### ✅ Add new env vars to 00-env.sh
```bash
# If you need a NEW variable that doesn't exist yet,
# add it to 00-env.sh in the appropriate section,
# then reference it everywhere else.
```

### ✅ Add new aliases to 02-aliases.sh
```bash
# If you need a NEW alias, add it to 02-aliases.sh
# organized by category.
```

### ✅ Module Placement Rules (Where to put new files)

| If you need to add... | Put it in... | Why |
|---|---|---|
| New env var / credential / IP / port | `00-env.sh` (in matching section) | SSOT for all env — sourced first |
| New color / style code | `01-colors.sh` | SSOT for color helpers `c`/`cn`/`_c`/`ctab`/`hline` — sourced before functions |
| New SSH / file transfer helper | `3worlds.sh` (or new file) | Sourced at Step 4 — needs SSOT paths ready |
| New alias | `02-aliases.sh` | Sourced at Step 5 — all paths/vars available |
| New prompt / theme | `theme.sh` | Sourced at Step 6 — needs colors loaded |
| New general function module | `functions/NN-name.sh` | Sourced at Step 7 — has access to ALL prior vars |
| New function that mutates runtime env (e.g. switches API keys) | `joe.sh` (bottom, after functions loop) | Step 8 — runs LAST so all functions already loaded |
| New AI profile / OpenCode helper | `joe.sh` (near `ai_profile`) | Step 8 — must come after `00-env.sh` OC_KEY_* exist |
| New syncctl library function | `tools/syncctl/lib/<module>.sh` | Sourced by syncctl CLI — guard with `_SYNCCTL_*_LOADED` (NO export!) |

> **⚠️ HARD RULE:** Do NOT add `source` calls inside `00-env.sh` for files
> that depend on it. Do NOT add `source` calls in `~/.bashrc` other than
> `joe.sh`. **`joe.sh` is the ONLY source orchestrator.**

> **⚠️ OpenCode Key Rotation Workflow:** When an API key expires:
> 1. Update `$OC_KEY_<PROFILE>` in `00-env.sh` (line ~160-170).
> 2. Default aliases (`$OPENCODE_GO_API_KEY` etc.) auto-update on next shell.
> 3. Run `pf <profile>` to refresh runtime if shell already open.
> 4. NEVER edit keys in `joe.sh` directly — that's what we just removed.

## 4. 📋 Pre-Flight Checklist (Before Writing Code)

Before creating or modifying any script, you MUST:

1. **Search first** — Use `Grep` to check if a variable/function already exists:
   - `grep -r "VARIABLE_NAME" ~/bashscripts/`
   - `grep -r "function_name()" ~/bashscripts/`
2. **Check 00-env.sh** — Is the path/IP/port/credential already defined there?
3. **Check 01-colors.sh** — Is the color/style already defined there?
4. **Check 02-aliases.sh** — Is the alias already defined there?
5. **Check functions/*.sh** — Does the function already exist?
6. **Use existing vars** — If it exists, USE it. If it doesn't, ADD it to the correct SSOT file first.

## 4.1 🔒 Pre-Commit Hook (SSOT/V4 Enforcement)

The repo has a pre-commit hook (`.github/hooks/pre-commit.json`) that runs `tools/agent-pre-commit.sh` on every `.sh` file edit. It enforces:

1. **Syntax Check:** `bash -n <file>` — catches parse errors before they reach the shell.
2. **SSOT/V4 Check:** `tools/safe-edit.sh <file>` — blocks inline ANSI escapes outside `01-colors.sh`, hardcoded IPs/keys, and V2 variable references.

**If the hook fails:** Fix the error before proceeding. The hook will block the edit.

**Manual verification:**
```bash
bash -n <file>                    # Syntax check
bash tools/safe-edit.sh <file>    # SSOT/V4 check
bash tools/ssot-audit.sh          # Full repo audit
```

## 4.2 🧪 Testing

Run the test suite to verify changes:
*(test suite removed 2026-08-18 — manual smoke test via `bash -n <file>` instead)*

## 4.3 ⚠️ Common Pitfalls & Gotchas

### 1. **Syncthing Caveat**
`~/bashscripts` is synced via Syncthing across devices. After editing files:
- Verify: `bash -n <file>` (syntax check)
- Be aware that edits may be overwritten if another device syncs simultaneously

### 2. **Cross-Shell Compatibility**
- `entry.sh` (Block Engine) is designed for both **bash** and **zsh**
- Avoid bash-specific features like `[[ ... ]]` or `${var//pattern/replace}` in public APIs
- Use the provided fallbacks in `entry.sh` for cross-shell support

### 3. **Source Order Matters**
- `bootstrap/00-env.sh` is sourced BEFORE any `functions/*.sh`
- `core/01-colors.sh` is sourced BEFORE any function module that prints colorized output
- Functions in `functions/*.sh` may source each other freely (alphabetical loop order)

### 4. **Pre-Commit Hook Enforcement**
The pre-commit hook (`tools/agent-pre-commit.sh`) will block edits that:
- Have syntax errors (`bash -n <file>` fails)
- Contain inline ANSI escapes outside `01-colors.sh`
- Contain hardcoded IPs/keys or V2 variable references

### 5. **SSOT Violations**
- Never redefine existing functions (e.g., `kp()` already exists in `functions/02-systems.sh`)
- Never create new env vars that overlap existing ones (e.g., `$oppc` already exists in `00-env.sh`)
- Never hardcode environment detection (joe.sh already handles this)

### 6. **Lessons** *(removed 2026-08-18)*
~~`lessons/exercise/*.sh` were test cases...~~ — removed in cleanup. Only `lessons/bash-fundamentals.md` remains for knowledge reference.

## 5. 🗂️ Adding New Content — Where Does It Go?

| What you're adding | Where it goes |
|---|---|
| New environment variable / path / IP / credential | `00-env.sh` (in the correct section) |
| New color or style | `01-colors.sh` |
| New alias | `02-aliases.sh` (in the correct category) |
| New system/network utility function | `functions/02-systems.sh` |
| New project runner / dashboard function | `functions/05-project.sh` |
| New OpenClaw function | `functions/04-openclaw.sh` |
| New SSH connection / file transfer | `3worlds.sh` |
| New File Manager feature | `functions/11-bash-manager.sh` |
| New prompt/theme element | `theme.sh` |
| New function module file | `functions/NN-name.sh` + add source line in `joe.sh` |

## 6. 🔑 Key Variables Quick Reference

### Core Paths (from `joe.sh`)
- `JOE_ENV` — Current environment: `TERMUX`, `WSL`, `GIT-BASH`, `MUMU`
- `hpc` — `/mnt/c/Users/User` (Windows home)
- `htm` — `/data/data/com.termux/files/home`
- `hwsl` — WSL home (usually `$HOME`)
- `SCRIPTS_PATH` — Path to this repo
- `DASHBOARD_DIR` — Path to dashboard project

### Derived Paths (from `00-env.sh`)
- `oppc` — `$hpc/openclaw`
- `dtpc` — `$hpc/Desktop`
- `hmp` — `$HOME/.hermes`
- `ENGINES_DIR` — `$DASHBOARD_DIR/api/engines`
- `PYTHON_VENV` — Python venv activate path
- `DASHBOARD_PYTHON` — Python activation script path

### Network (from `00-env.sh`)
- `WINDOWS_IP`, `WINDOWS_USER`
- `WSL_IP`, `WSL_USER`
- `TERMUX_IP`, `TERMUX_USER`, `TERMUX_PORT`
- `DEBIAN_IP`, `DEBIAN_USER`, `DEBIAN_PORT`

### Colors V3 (from `01-colors.sh`) — อัปเดต 2026-08-02

**NO color variables** (`$RED`, `$NC`, `$RESET` are GONE).
**Helpers:** `c`, `cn`, `color`, `_c/_r/_b/_d/_i/_u`, `ctab`, `hline`, `rc`, `rc1`, `rc2`, `cmp`, `cmp2`, `c256`, `rainbo`

**พิมพ์สี (ตัวหลัก):**
```bash
# c  = พิมพ์สี ไม่มี newline — ต่อสีในบรรทัดเดียวได้ (ตัวหลัก)
# cn = พิมพ์สี + newline — ปิดท้ายบรรทัด
c  202 b "hello"      # ต่อสีไปเรื่อยๆ
cn 202 b "hello"      # จบบรรทัด

# layout หลายสีบรรทัดเดียว: c ต่อๆ แล้วจบด้วย cn
c 46 b "ON "; c 226 "| "; cn 208 "WARN"   # → ON | WARN
```

**Escape helpers (ต่อเอง ไม่มี newline — เขียนสั้น):**
```bash
echo -e "$(_c 208)$(_b)text$(_r)"   # = \e[38;5;208m\e[1mtext\e[0m
# _c <num> = สี 256 | _r = reset | _b = bold | _d = dim | _i = italic | _u = underline
```

**ตาราง / เส้นคั่น (layout):**
```bash
ctab "46:22 244:28 0:0" "fm ls" "fm ls [path]" "desc"  # ตารางหลายคอลัมน์
hline 66             # เส้นคั่น dim ─────
hline 25 141         # เส้นคั่นสีม่วง
```
- `ctab` spec = `[style][color]:width` — style `b/d/u` ต่อกันได้, color `0`=default / ตัวเลข=256 / `x`=ไม่ wrap สี, width `0`=auto
- `ctab` แปลง `\e` literal ใน args → ESC จริงอัตโนมัติ (กัน bash เก่า Termux/Git Bash)

**4 ways to color — pick what fits:**

```bash
# 1. V3 helper (หลัก — minimal)
c 202 b "hello"       # ไม่มี newline (ต่อได้)
cn 202 b "hello"      # มี newline (จบบรรทัด)

# 2. Escape helpers (ต่อเอง)
echo -e "$(_c 202)$(_b)hello$(_r)"

# 3. V2 color() (rich: short name + style + 256 — legacy newline)
color r b "red bold"            # short name
color 202 b "color 202 bold"    # 256 number

# 4. V2 random palettes (Joe's favorites)
rc b "rainbow bold"             # 12-color vibrant
rc1 "pastel"                    # 12-color earthy
rc2 b "neon bold"               # 10-color bold
```

**Cheat sheet (Joe's favorites):**
| Color | Code |  | Color | Code |  | Color | Code |
|---|---|---|---|---|---|---|---|
| red | 196 | | cyan | 51 | | gray | 244 |
| lred | 203 | | lcyan | 87 | | orange | 208 |
| green | 82 | | blue | 33 | | purple | 141 |
| lgreen | 46 | | lblue | 75 | | pink | 213 |
| yellow | 226 | | white | 255 | | dim | 245 |

**Full chart:** `bash tools/color-chart.sh`

**❌ NEVER use (all removed):**
- `$RED`, `$LBLUE`, `$NC`, `$RESET`, `$PURPLE`, `$GYAN` — gone
- `ST_B/ST_D/ST_I/ST_U`/`R0` — gone (ใช้ `$(_b)`/`$(_d)`/`$(_i)`/`$(_u)`/`$(_r)` แทน)
- Any hardcoded color var
- ⚠️ ห้ามตั้งชื่อ helper ชนคำสั่งจริง (เช่น `cp` ชน `/usr/bin/cp` → ใช้ `cn` แทน)

### Function Paths (from `functions/03-fpath.sh`)
- `FUNC_DIR` — `$SCRIPTS_PATH/functions`
- `fpth`, `fstm`, `fop`, `fpj`, `falias` — shortcuts to function files

## 7. ⚡ Summary Rule

> **If a variable, color, alias, or function already exists in the SSOT files — USE IT. If it doesn't exist yet — ADD IT to the correct SSOT file, then reference it everywhere else. NEVER duplicate. NEVER hardcode.**

---

## 8. 🔗 Related Knowledge (nexus_vault)

This repo's SSOT is `~/bashscripts/`. The agent identity / knowledge SSOT is at `~/nexus_vault/`. They are linked:

| Topic | Vault Knowledge | Bashscripts file |
|---|---|---|
| Service patterns (openclaw, syncthing) | `~/nexus_vault/knowledge/wsl-services` | `functions/04-openclaw.sh` |
| Shell function patterns (getopts, OPTIND) | `~/nexus_vault/knowledge/bashscripts` | (this file + `functions/*.sh`) |
| Port map (syncthing, tailscale IPs) | `~/nexus_vault/knowledge/ports` | `00-env.sh` |
| Color definitions | `~/nexus_vault/knowledge/bashscripts` | `01-colors.sh` |
| Tailscale topology | `~/nexus_vault/knowledge/tailscale` | `00-env.sh` (WINDOWS_IP, WSL_IP, etc.) |

**Daily logs** in `~/nexus_vault/memory/daily/` track work sessions. Check today's log before making changes — recent context matters.

## 9. � Syncctl — Syncthing Ownership Controller

> **syncctl** manages single-master ownership for the `bashscripts` Syncthing folder
> across WSL/Windows/Termux/MuMu. Enforces: 1 Master (sendonly) + N replicas (receiveonly).

### Architecture
- **SSOT for config:** `00-env.sh` owns `NODE_*_ST_ID`, `ST_KEY_*`, `NODE_*_ST_URL`
- **SSOT for folder ID:** `config.sh` sets `SYNCCTL_FOLDER_ID=qrkzm-pecck` (Syncthing ID, NOT label)
- **Sourced by joe.sh** as functions only — `main "$@"` guarded by `BASH_SOURCE[0] == $0`
- **Standalone execution:** via symlink `~/.local/bin/syncctl` → repo `tools/syncctl/syncctl`

### ⚠️ Critical Pitfalls (learned the hard way, 2026-08-04)

**1. Lib guards must NEVER be exported**
```bash
# ❌ WRONG — leaks to child processes, breaks standalone syncctl
export _SYNCCTL_CONFIG_LOADED=1

# ✅ CORRECT — plain variable, only prevents re-source in same process
_SYNCCTL_CONFIG_LOADED=1
```
When joe.sh sources syncctl, exported guard vars leak to child processes.
Standalone `syncctl init wsl` inherits them → ALL guards trigger → NO functions defined.

**2. `BASH_SOURCE[0] == $0` guard for sourced scripts**
syncctl is sourced by joe.sh AND executed standalone. The `main "$@"` call must be guarded:
```bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
```

**3. Folder ID ≠ Label**
```bash
# ❌ WRONG — "bashscripts" is the Syncthing display label, not the REST API ID
export SYNCCTL_FOLDER_ID="bashscripts"

# ✅ CORRECT — use the actual Syncthing folder ID
export SYNCCTL_FOLDER_ID="qrkzm-pecck"
```
Query with: `curl -s -H "X-API-Key: $ST_KEY_WSL" "$NODE_WSL_ST_URL/rest/config/folders"`

**4. No `jq` dependency — use `printf` or `syncctl_jq`**
WSL doesn't have `jq` installed. Use `printf` for simple JSON or `syncctl_jq` (python3 fallback):
```bash
# ❌ WRONG — jq may not be installed
data="$(jq -nc --arg t "$new_type" '{type:$t}')"

# ✅ CORRECT — no external dependency
data="$(printf '{"type":"%s"}' "$new_type")"
```

**5. Init mode needs relaxed checks**
`checkpoint_run --init` skips `check_local_state` and `check_cluster_state` (devices may be offline, conflicts normal during first setup). `apply_ownership "$target" 1` tolerates unreachable devices.

### Quick Reference
```bash
syncctl status          # Show master, devices, folder, checkpoint
syncctl init wsl        # First-time setup (WSL = master)
syncctl checkpoint      # Verify cluster clean
syncctl transfer windows --dry-run   # Preview handover
syncctl transfer windows --reason "hotfix"  # Actual handover
syncctl doctor          # Full audit
syncctl recover         # If handover was interrupted
```

## 9.1 🎨 Block Engine — Terminal UI Framework

> **Block Engine** renders styled status dashboards in the terminal.
> For detailed instructions, see `.github/instructions/joe-block.instructions.md`.

### Architecture (Rows → Layout → Theme → Renderer)
```
entry.sh (m/dashboard_array)
    ↓
status.sh (data providers: status_new, op_profile)
    ↓
layout.sh (calculates dimensions: _LAYOUT[])
    ↓
theme.sh (loads style from block_style.sh: _THEME[])
    ↓
renderer.sh (draws borders, rows, separators)
```

### Quick Reference
```bash
m a                    # Dashboard with style "a"
m b                    # Dashboard with style "b"
m_random               # Random style
m_animate              # Animated style rotation
dashboard_array "${ROWS[@]}"  # Render from array
```

### Key Files
| File | Purpose |
|------|---------|
| `functions/joe-block/entry.sh` | Public API (m, dashboard, dashboard_array) |
| `functions/joe-block/block/status.sh` | Data providers (status_new, op_profile) |
| `functions/joe-block/block/layout.sh` | Dimension calculations |
| `functions/joe-block/block/theme.sh` | Style loading and color compilation |
| `functions/joe-block/block/renderer.sh` | ASCII rendering |
| `functions/joe-block/styles/block_style.sh` | Style definitions (a/b/c/default/random) |

### SSOT Compliance
- Never hardcode colors — use helpers from `01-colors.sh`
- Use `set_ <var> <value>` in `styles/block_style.sh` to populate `_THEME` and `_LAYOUT`
- Cross-shell support: avoid bash-specific features in public API
- Idempotent sourcing: modules in `block/` are sourced automatically by `entry.sh`

## 9.2 🤖 Hermes AI Integration

> **Hermes** provides AI-powered assistance within the terminal.
> Located at `plugins/hermes/hermes.sh`.

### Quick Reference
```bash
hermes                  # Launch Hermes AI assistant
hermes_load             # Source Hermes (from 00-fm-loader.sh)
```

### Key Files
| File | Purpose |
|------|---------|
| `plugins/hermes/hermes.sh` | Main Hermes AI integration |
| `functions/00.1-function-tools.sh` | Shared helpers (sources hermes.sh) |

### SSOT Compliance
- Hermes config is in `00-env.sh` (`$HERMES_DIR`, `$hmp`)
- Source via `plugins/hermes/hermes.sh` or `tools/hermes.sh`
- Do not redefine Hermes functions in other files

## 9.3 📁 File Manager (fm/xfm)

> **File Manager** provides ls/cp/mv/tree/ssh/push/pull operations.
> Located at `functions/11-bash-manager.sh`.

### Quick Reference
```bash
fm                      # Launch file manager
fm ls [path]            # List directory
fm cp <src> <dst>       # Copy file
fm mv <src> <dst>       # Move file
fm tree [path]          # Show directory tree
xfm                     # Cross-machine file manager
```

### Key Files
| File | Purpose |
|------|---------|
| `functions/11-bash-manager.sh` | Main file manager (fm/xfm) |
| `functions/00-fm-loader.sh` | File manager bootstrapper |

### SSOT Compliance
- Uses `$JOE_CORE/01-colors.sh` for color output
- Uses `$JOE_ROOT/bootstrap/00-env.sh` for environment variables
- Do not redefine `fm` or `xfm` functions in other files

## 9.4 🌐 SSH & Transfer (3worlds.sh)

> **3worlds.sh** provides SSH tunneling and file transfer between devices.
> Located at `core/3worlds.sh`.

### Quick Reference
```bash
tm <cmd>                # SSH to Termux
tw <cmd>                # SSH to Windows
wsl <cmd>               # SSH to WSL (from Windows)
push <src> <dst>        # Push file to remote
pull <src> <dst>        # Pull file from remote
cpw2t <src> <dst>       # Copy WSL → Termux
cpt2w <src> <dst>       # Copy Termux → WSL
```

### Key Files
| File | Purpose |
|------|---------|
| `core/3worlds.sh` | SSH/transfer functions (tm/tw/wsl/push/pull) |

### SSOT Compliance
- Network config is in `00-env.sh` (`$WINDOWS_IP`, `$TERMUX_IP`, etc.)
- SSH keys are in `00-env.sh` (`$ST_KEY_*`)
- Do not redefine `tm`, `tw`, `wsl`, `push`, `pull` functions in other files

## 9.5 🎨 Color System (V3/V4)

> **Color System** provides terminal color helpers.
> Located at `core/01-colors.sh`.

### Quick Reference
```bash
c 202 b "hello"         # Print colored text (no newline)
cn 208 "WARN"           # Print colored text + newline
color r b "error"       # Legacy helper (has newline)
ctab "label" "value"    # Print labeled table row
hline "-" 50            # Print horizontal line
rc b "info"             # Random palette color
```

### Key Files
| File | Purpose |
|------|---------|
| `core/01-colors.sh` | Color engine V3/V4 (c/cn/color/ctab/hline/rc) |

### SSOT Compliance
- **ONLY** `01-colors.sh` is allowed to contain raw `\e[` or `\033[`
- All other files MUST use helpers: `c`, `cn`, `color`, `ctab`, `hline`, `rc`
- Enforcement: `tools/safe-edit.sh` + `tools/ssot-audit.sh` will FAIL any file with inline ANSI outside `01-colors.sh`
- See Color System V3/V4 Quick Reference in Section 2

## 9.6 🔍 Environment Detection (joe.sh)

> **joe.sh** detects the current environment and sets `JOE_ENV`.
> Located at `joe.sh`.

### Quick Reference
```bash
# joe.sh detects JOE_ENV automatically:
# TERMUX | MUMU | WSL | GIT-BASH

# Check current environment
echo $JOE_ENV

# Environment-specific logic
if [[ "$JOE_ENV" == "TERMUX" ]]; then
    # Termux-specific logic
elif [[ "$JOE_ENV" == "WSL" ]]; then
    # WSL-specific logic
fi
```

### Key Files
| File | Purpose |
|------|---------|
| `joe.sh` | Main entry point, environment detection |

### SSOT Compliance
- `JOE_ENV` is set by `joe.sh` Step 0 — do not override it
- Environment detection is centralized in `joe.sh` — do not duplicate in other files
- Use `$JOE_ENV` for environment branching, not hardcoded checks

## 9.7 🚀 Boot Sequence (joe.sh)

> **joe.sh** is the ONLY entry point for loading the bashscripts ecosystem.
> Located at `joe.sh`.

### Quick Reference
```bash
# Load order (set by joe.sh):
source ~/.bashrc or ~/.zshrc
  └─ source joe.sh                    [BOOSTER — only entry point]
       ├─ Step 0: detect JOE_ENV      (TERMUX | MUMU | WSL | GIT-BASH)
       ├─ Step 1: set SSOT, SCRIPTS_PATH, hpc/htm/hwsl, DASHBOARD_DIR
       ├─ Step 1.5: CRLF self-heal    (auto-fix Windows line endings)
       ├─ Step 2: set JOE_ROOT/JOE_CORE/JOE_PLUGINS/JOE_TOOLS
       │
       ├─ source bootstrap/00-env.sh  ← env vars, paths, keys
       ├─ source core/01-colors.sh    ← c()/cn()/color(), ctab, hline, rc()
       ├─ auto-start sshd & ssh-agent
       ├─ source core/3worlds.sh      ← tm/tw/wsl/push/pull
       ├─ source core/02-aliases.sh   ← cls, h, reload, etc.
       ├─ source core/profiles.sh     ← ai_profile() + alias pf
       ├─ source core/theme.sh        ← prompt & PROMPT_COMMAND
       │
       ├─ source functions/*.sh       ← glob: all function modules
       │   └─ source plugins/block_engine/entry.sh  ← m/dashboard
       ├─ source plugins/syncctl/syncctl  ← syncthing controller
       │
       └─ startup tasks               ← syncthing_auto, rc_del
```

### Key Files
| File | Purpose |
|------|---------|
| `joe.sh` | Main entry point, boot orchestrator |

### SSOT Compliance
- `joe.sh` is the ONLY source orchestrator — do not add `source` calls in `~/.bashrc` other than `joe.sh`
- Do NOT add `source` calls inside `00-env.sh` for files that depend on it
- Source order matters — follow the boot sequence exactly

## 10. �📋 Quick Reference for AI Agents

### Testing Changes
```bash
# Reload config after changes
source ~/bashscripts/joe.sh

# Test specific function
source ~/bashscripts/functions/02-systems.sh
fp 8022  # Test port check

# Test color function
source ~/bashscripts/01-colors.sh
cn lg b "Test message"  # Should show light green bold (cn = จบบรรทัด)
```

### Common Pitfalls
1. **Port conflicts** — Always check with `fp <port>` before starting services
2. **SSH timeouts** — Use `tm` for Termux SSH, `tw` for Windows SSH
3. **Python venv** — Always `source $PYTHON_VENV` before running Python scripts
4. **JOE_ENV detection** — Check `$JOE_ENV` before running environment-specific code

### File Naming Conventions
- `00-`, `01-`, `02-` prefixes = load order priority
- `functions/*.sh` = modular function files
- `tools/*.sh` = utility scripts (not auto-loaded)
- `*shbk` or `*bk` = backup files (can be ignored)

### Key Aliases for Quick Navigation
```bash
bsc      # cd to bashscripts repo
oppc     # cd to openclaw project
dtpc     # cd to Desktop
hmp      # cd to hermes config
reload   # reload bash config
re       # clear + reload
```

### SSH Quick Commands
```bash
tm <cmd>      # SSH to Termux
tw <cmd>      # SSH to Windows
wsl <cmd>     # SSH to WSL (from Windows)
cpw2t <src> <dst>  # Copy WSL → Termux
cpt2w <src> <dst>  # Copy Termux → WSL
```

## 11. 🔄 Maintenance Notes

### Syncthing Integration
- The repo is synced across devices via Syncthing
- SSOT variables for Syncthing are in `00-env.sh`
- Daily logs in `~/nexus_vault/memory/daily/` track changes

### Backup Strategy
- `tools/*shbk` files = backup copies (safe to ignore)
- `tools/auto_block-v2.txt` = block engine reference
- Keep backups minimal — prefer git history over file copies

### Adding New Features
1. Check if similar functionality exists (grep first!)
2. Add new env vars to `00-env.sh`
3. Add new functions to appropriate `functions/*.sh` file
4. Add new aliases to `02-aliases.sh`
5. Test with `source ~/bashscripts/joe.sh` before committing
