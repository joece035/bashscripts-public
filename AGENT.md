---
name: bashscripts-agent
description: Agent for working with Joe's Bashscripts ecosystem. Must follow SSOT architecture rules strictly. Updated 2026-08-23 after joe.sh refactor (new ssot_load pattern, SSOT-based paths, renamed core files).
tools: Read, Grep, Glob, Bash
---

# 🏗️ Bashscripts Agent — JOE_ENV Architecture Rules

> **⚠️ MANDATORY: Every agent working in this repo MUST follow these rules. No exceptions.**
>
> **📌 Last updated:** 2026-08-23 — after `joe.sh` refactor. Major changes:
> - Boot sequence now uses `ssot_load()` (explicit list, see §3 + §9.7)
> - Canonical paths are now **`$SSOT` / `$SCRIPTS_PATH`** (set from `JOE_ENV`); `$JOE_ROOT` is **legacy** (still exported by `bootstrap/setup.sh`)
> - Renamed: `core/02-aliases.sh` → `core/aliases.sh`
> - Moved: `functions/11-bash-manager.sh` → `core/bash-manager.sh`
> - Added: `core/ssh-config.sh` (cb_copy/ssh_kgen/ssh_kadd), `core/ensure.sh` (auto-install helpers)
> - Block engine lives at `functions/joe-block/` (canonical) — `plugins/block_engine/` is **legacy/duplicate**
> - `syncctl` lives at `tools/syncctl/syncctl` (canonical) — `plugins/syncctl/` is **legacy/duplicate**
> - `MY_DEVICE` env var is now the preferred way to set `JOE_ENV` (set externally, e.g. `.env` / `.bashrc`)
> - `pf <profile>` is called from `joe.sh` to seed AI keys at boot (default `mom`)

## 1. Project Overview

**Purpose:** Joe's Personal Command Center — a cross-platform bash/zsh scripts ecosystem that works on **Termux, WSL, and Git Bash**. It provides environment detection, SSH tunneling between devices, file management, and a unified CLI experience.

**Key Design Principle:** **Single Source of Truth (SSOT)** — each domain has ONE canonical file that owns its variables/functions. All other files reference (never redefine) these definitions.

**Path System (post 2026-08-23 refactor):**
- **Canonical:** `$SSOT` (set per `JOE_ENV` in `joe.sh`), aliased to `$SCRIPTS_PATH` and `$COLOR_PATH`.
- **Legacy:** `$JOE_ROOT`, `$JOE_CORE`, `$JOE_PLUGINS`, `$JOE_TOOLS` are still exported by `bootstrap/setup.sh` for **backward compat only**. New code MUST use `$SSOT` / `$SCRIPTS_PATH`.
- See `DEPENDENCY_MAP.md` for full module graph.

## 📚 Related Instruction Files

| File | Scope | When to Load |
|------|-------|--------------|
| `.github/instructions/joe-block.instructions.md` | Block Engine (UI rendering) | When working with `functions/joe-block/` |
| `.github/skills/syncctl/SKILL.md` | Syncthing cluster management | When using `syncctl` commands |
| `.github/prompts/handover-report.prompt.md` | Handover report generation | When generating handover reports |

## 2. Architecture Overview (JOE_ENV + SSOT)

This repo uses a **JOE_ENV directory structure** with strict SSOT rules. Each file is the **canonical source** for its domain. When creating or modifying scripts, you **MUST** reference existing variables/functions via `$SSOT` / `$SCRIPTS_PATH` (canonical) — never redefine or hardcode them. Legacy `$JOE_ROOT` / `$JOE_CORE` / `$JOE_PLUGINS` / `$JOE_TOOLS` are still exported but only for backward compat.

### Directory Structure

```
bashscripts/
├── joe.sh                    ← MAIN ENTRY POINT (booster — source this from .bashrc/.zshrc)
├── bootstrap/
│   ├── 00-env.sh             ← Environment variables (SSOT)
│   └── setup.sh              ← Installer (still exports legacy $JOE_ROOT)
├── core/
│   ├── 01-colors.sh          ← Color engine V3/V4 (SSOT — only file allowed to contain raw \e[)
│   ├── aliases.sh            ← All aliases (SSOT) ← renamed from 02-aliases.sh 2026-08-23
│   ├── 3worlds.sh            ← SSH/transfer (SSOT: tm/tw/wsl/push/pull)
│   ├── ssh-config.sh         ← SSH config helpers (cb_copy / ssh_kgen / ssh_kadd) — NEW 2026-08-23
│   ├── ensure.sh             ← Auto-install missing packages via pkg/apt — NEW 2026-08-23
│   ├── bash-manager.sh       ← File Manager CLI (fm/xfm) — moved from functions/ 2026-08-23
│   ├── profiles.sh           ← AI profile switching (ai_profile / pf / stc / cstats)
│   └── theme.sh              ← Prompt customization (PROMPT_COMMAND)
├── functions/                ← Function modules (glob-loaded by joe.sh after ssot_load)
│   ├── 00-fm-loader.sh       ← FM bootstrapper (sources joe-block + tools/{hermes,merge,wtf,ai_block})
│   ├── 00.1-function-tools.sh← Shared helpers (mth/math/backup)
│   ├── 02-systems.sh         ← System utils (kp/fpk/gpc/adb/scrcpy)
│   ├── 03-fpath.sh           ← Path functions (fn/ep/hop/sd/cdc)
│   ├── 04-openclaw.sh        ← OpenClaw integration
│   ├── 05-pathx.sh           ← PATH explorer
│   ├── 05-project.sh         ← Project runners
│   ├── 07-wtf.sh             ← Diagnostic tool
│   ├── 08.hermes.sh          ← Hermes integration (note the DOT, not 08-hermes.sh)
│   ├── 09-all_block_status.sh← Block status dashboard
│   ├── backup.sh             ← Backup helpers
│   ├── clean.sh              ← Cleanup helpers
│   ├── tools.sh              ← Misc tools
│   └── joe-block/            ← ✅ CANONICAL Block Engine (entry.sh / block/ / styles/)
├── tools/                    ← Standalone executables (NOT auto-loaded by joe.sh)
│   ├── safe-edit.sh          ← Pre-commit guard (ANSI/SSOT check)
│   ├── ssot-audit.sh         ← SSOT drift detector
│   ├── merge.sh              ← Tree/merge tools (sourced by 00-fm-loader.sh)
│   ├── agent-pre-commit.sh   ← Pre-commit hook runner
│   ├── hermes.sh             ← Hermes CLI wrapper (sourced by 00-fm-loader.sh)
│   ├── mumu-debug.sh         ← MUMU environment debugger
│   ├── install-syncthing-service.sh ← Git-Bash syncthing scheduler
│   ├── patch_theme.sh        ← Theme patcher
│   ├── color-chart.sh        ← Color palette display
│   ├── ai_block.sh           ← AI block helper (sourced by 00-fm-loader.sh)
│   ├── files_manage.sh       ← File management helpers
│   ├── wtf.sh                ← WTF debug tool (sourced by 00-fm-loader.sh)
│   └── syncctl/syncctl       ← ✅ CANONICAL syncctl CLI (sourced by joe.sh via ssot_load)
├── plugins/                  ← ⚠️ LEGACY duplicates — see §4.3 #9 below
│   ├── block_engine/         ← ⚠️ duplicate of functions/joe-block/ — DO NOT USE
│   ├── syncctl/              ← ⚠️ duplicate of tools/syncctl/ — DO NOT USE
│   └── hermes/hermes.sh      ← Hermes plugin (legacy)
├── modules/                  ← Optional legacy helpers (ai_block.sh / color-chart.sh)
├── profiles/                 ← Shell profile templates (termux/, etc.)
└── lessons/                  ← Learning materials (bash-fundamentals.md only — exercises removed 2026-08-18)
```

### Path Variable System

> Post 2026-08-23 refactor. **Canonical** vars are set by `joe.sh` Step 1 case
> (per-env). **Legacy** vars are still exported by `bootstrap/setup.sh` for
> backward compat. New code MUST use canonical vars.

| Variable | Value | Status | Set by |
|----------|-------|--------|--------|
| `SSOT` | `$HOME/bashscripts` (per env) | ✅ Canonical | `joe.sh` Step 1 case |
| `SCRIPTS_PATH` | `$SSOT` | ✅ Canonical alias | `joe.sh` global vars |
| `COLOR_PATH` | `$SSOT` | ✅ Canonical alias | `joe.sh` global vars |
| `JOE_ROOT` | `$HOME/bashscripts` | ⚠️ Legacy | `bootstrap/setup.sh` |
| `JOE_CORE` | `$JOE_ROOT/core` | ⚠️ Legacy | `bootstrap/setup.sh` |
| `JOE_FUNCTIONS` | `$JOE_ROOT/functions` | ⚠️ Legacy | `bootstrap/setup.sh` |
| `JOE_PLUGINS` | `$JOE_ROOT/plugins` | ⚠️ Legacy | `bootstrap/setup.sh` |
| `JOE_TOOLS` | `$JOE_ROOT/tools` | ⚠️ Legacy | `bootstrap/setup.sh` |

> **Rule of thumb:** Prefer `$SSOT` everywhere. The two values usually
> resolve to the same path, but `$JOE_PLUGINS` points to the **legacy**
> `plugins/` tree (which is being phased out).

### Load Order (set by `joe.sh` — verified 2026-08-23 after refactor)

> **⚠️ This is the AUTHORITATIVE order.** When adding new modules, integrate
> into the correct stage below. Do NOT add `source` calls outside of `joe.sh`.
> **Only the explicit `[ -f ... ] && source ...` lines and `ssot_load()` actually load files.**

```
~/.bashrc or ~/.zshrc
  └─ source joe.sh                          [BOOSTER — only entry point]
       │
       ├─ Step 0: JOE_ENV fallback          (read MY_DEVICE if exported; else trust JOE_ENV)
       ├─ Step 1: case "$JOE_ENV"           → export SSOT, DASHBOARD_DIR, hpc/htm/hwsl,
       │                                      OBSIDIAN_VAULT, home, nexus_vault,
       │                                      MAIN_SYNC_DIR, SSH_PORT, PYTHON_VENV
       │           (TERMUX | MUMU | WSL | GIT-BASH)
       │
       ├─ Global vars (after case)          → SCRIPTS_PATH=$SSOT, COLOR_PATH=$SSOT,
       │                                      msync, htm, OP_DIR, SSH_MUMU/TERMUX/WSL/WIN_PORT
       │
       ├─ Step 1.5: CRLF SELF-HEAL          (sed CRLF→LF on $SSOT/**/*.sh; stderr-only,
       │                                      Powerlevel10k instant-prompt safe)
       │
       ├─ source bootstrap/00-env.sh        ← env vars, paths, keys (HERMES_DIR, NODE_*,
       │                                      OC_KEY_*, PYTHON_VENV, BRAVE_API_KEY, alpha…)
       ├─ source core/01-colors.sh          ← c()/cn()/color(), ctab, hline, rc(),
       │                                      _c/_r/_b/_d/_i/_u (SSOT for ANSI)
       │
       ├─ auto-start ssh-agent              (only if SSH_AUTH_SOCK unset / ssh-add -l fails;
       │                                    adds ~/.ssh/id_ed25519 if present; warns to stderr)
       ├─ auto-start sshd                   (WSL → service ssh; TERMUX/MUMU → sshd -p $SSH_PORT;
       │                                    pgrep -f "sshd.*-p.*${SSH_PORT}" check;
       │                                    all output to stderr for p10k compat)
       │
       ├─ ssot_load "1"                     ← **declared** loader (see ⚠️ note below):
       │     local load_files=(
       │       "$SSOT/core/ssh-config.sh"
       │       "$SSOT/core/3worlds.sh"
       │       "$SSOT/core/aliases.sh"
       │       "$SSOT/core/profiles.sh"
       │       "$SSOT/core/theme.sh"
       │       "$SSOT/functions"/*.sh
       │       "$SSOT/tools/syncctl/syncctl"
       │     )
       │     # ⚠️ CURRENTLY: ssot_load only PRINTS the list (when called with "1");
       │     #   it does NOT actually source anything because the planned
       │     #   `for f in "${load_files[@]}"; do source "$f"; done` loop is missing.
       │     #   Today, only bootstrap/00-env.sh + core/01-colors.sh are explicitly
       │     #   sourced. The rest are loaded indirectly via functions/00-fm-loader.sh
       │     #   (which sources joe-block + tools/{hermes,merge,wtf,ai_block}).
       │     #   See §8 — DO NOT add code that depends on ssot_load() doing the work
       │     #   until the loop is added back.
       │
       ├─ startup tasks (per JOE_ENV)       → TERMUX|MUMU: rc_delete >&2
       │                                      WSL:        syncthing_auto
       │                                      GIT-BASH:   (no-op)
       ├─ pf mom                             → seed OpenCode API keys at boot (ai_profile() in core/profiles.sh)
       └─ set +u                             → ble.sh restores set -u per cmd; we don't want
                                              nounset errors on first source of unset vars (dbp, $2, …)
```

**Critical invariants:**
- `bootstrap/00-env.sh` is sourced BEFORE any `functions/*.sh` — every function
  module can safely read `$OC_KEY_*`, `$WINDOWS_IP`, `$ST_KEY_*`, etc.
- `core/01-colors.sh` is sourced BEFORE any function module that prints
  colorized output (e.g. `cn 202 b "msg"`).
- `core/ssh-config.sh` and `core/3worlds.sh` are **declared** in `ssot_load()` but
  currently NOT sourced there (see ⚠️ above). They get loaded transitively through
  `functions/00-fm-loader.sh` → `core/bash-manager.sh` or via user-driven `tm`/`tw` calls.
- Functions in `functions/*.sh` may source each other freely (alphabetical
  loop order: 00-fm-loader → 00.1-function-tools → 02-systems → ...).
- `ai_profile()` (in `core/profiles.sh`) is the **only** function that mutates
  `OPENCODE_*` vars at runtime. `joe.sh` calls `pf mom` at the very end to seed
  the default profile. Never reassign these from other files.
- Path variables: `SSOT` is the canonical name (set in joe.sh Step 1 case),
  `SCRIPTS_PATH` = `COLOR_PATH` = `$SSOT` (aliases).
  `JOE_ROOT` / `JOE_CORE` / `JOE_PLUGINS` / `JOE_TOOLS` are **legacy** (still
  exported by `bootstrap/setup.sh`) — prefer `$SSOT` in new code.
- All init-time console output (CRLF notice, sshd started, pf status) MUST go to
  **stderr**, never stdout — otherwise Powerlevel10k instant prompt breaks.

### SSOT File Map (อัปเดต 2026-08-23 — joe.sh refactor)

> **JOE_ENV มีค่าเดียวเท่านั้น: `TERMUX | MUMU | WSL | GIT-BASH`**
> Canonical paths use `$SSOT` (or its alias `$SCRIPTS_PATH`). `$JOE_ROOT` family
> is legacy but still exported by `bootstrap/setup.sh`.

| File | Domain | What it owns |
|------|--------|-------------|
| `joe.sh` | Boot | `JOE_ENV` fallback (read `MY_DEVICE`), per-env case (sets `SSOT`, `DASHBOARD_DIR`, `hpc/htm/hwsl`, `SSH_PORT`, `PYTHON_VENV`, `OBSIDIAN_VAULT`, `home`, `nexus_vault`, `MAIN_SYNC_DIR`), global vars (`SCRIPTS_PATH`, `COLOR_PATH`, `msync`, `htm`, `OP_DIR`), CRLF self-heal, explicit sources of `bootstrap/00-env.sh` + `core/01-colors.sh`, ssh-agent/sshd auto-start, `ssot_load()` (declared loader — see ⚠️ in §3), per-env startup tasks (`rc_delete` / `syncthing_auto`), `pf mom` final seed, `set +u`. Global helpers: `pp()` (smart reload). |
| `bootstrap/00-env.sh` | Environment | Per-env workspace paths (`HERMES_DIR`, `PYTHON_VENV`, `SDCARD_PATH`, `NODE_HOST`, `WIN_PATH`), global vars (`profile`, `oppc`, `dpc`/`dtpc`, `hmp`, `HERMES_LOG_DIR`, `BRAVE_API_KEY`, `alpha`/`ALPHA_DIR`, `storage`, `_SHELL`, `_USER`), `ai_bin()` (sets `OPENCLAW_BIN` / `HERMES_BIN`), `ENGINES_DIR`. |
| `core/01-colors.sh` | Colors (V3/V4) | `c()` (no newline), `cn()` (newline), `color()` (legacy), `_c/_r/_b/_d/_i/_u` (raw escape), `ctab()` (table), `hline()` (divider), `rc()` (random palette), `rc1`/`rc2`/`cmp`/`cmp2`/`c256`/`rainbo`. **ONLY file allowed to contain raw `\e[` / `\033[`.** |
| `core/aliases.sh` | Aliases | All aliases (`cls`, `h`, `reload`, `merge`, `fm`, `unbinding`, etc.) — sources `$SSOT/tools/merge.sh`. ⚠️ Renamed from `02-aliases.sh` 2026-08-23 (header comment not yet updated). |
| `core/3worlds.sh` | SSH/Transfer | `_detect_world()` / `_MY_WORLD`, transport layer (`_ssh_node`, `_rsync_to/_rsync_from`), service layer (`_st_fetch`, `_st_autostart`, `syncthing_auto`), public API (`tm`, `tw`, `wsl`, `push`, `update`, `cptw/cpw2t`). |
| `core/ssh-config.sh` | SSH Config | Clipboard helpers (`cb_read`, `cb_copy`), key generation (`ssh_kgen`), authorized_keys management (`ssh_kadd`). **NEW 2026-08-23.** |
| `core/ensure.sh` | Auto-install | `ensure_ <cmd> [pkg]` — auto-install missing commands via `pkg` (Termux) or `apt` (Debian/WSL). Handles root vs sudo, single `apt update` per session (`JOE_APT_UPDATED`). **NEW 2026-08-23.** |
| `core/bash-manager.sh` | File Manager | `fm` (ls/cp/mv/tree/ssh/push/pull), `xfm` (cross-machine). Self-bootstraps `$SSOT/core/01-colors.sh` + `$SSOT/bootstrap/00-env.sh` if sourced standalone. **MOVED from `functions/11-bash-manager.sh` 2026-08-23.** |
| `core/profiles.sh` | AI Profile | `ai_profile()` (mom/joe) + alias `pf`, `current_stats()` + aliases `stc` / `cstats`, `clear_cache`. Live API probe (5s timeout). |
| `core/theme.sh` | Prompt | `_git_prompt()` (lightweight), `_exit_status()`, `_set_prompt()` (uses `_c/_b/_r` raw escapes for PS1). |
| `functions/00-fm-loader.sh` | FM Loader | `fm()` command, sources `$SSOT/functions/joe-block/styles/block_style.sh`, `$SSOT/functions/joe-block/entry.sh`, and `$SSOT/tools/{ai_block,tools,merge,wtf}.sh`. ⚠️ Has legacy `core/bash-manager.sh` reference (works post-move). |
| `functions/00.1-function-tools.sh` | Function Tools | `agent_md()`, backup helpers, `mth()` math. References `syncctl` and `hermes` paths. |
| `functions/02-systems.sh` | System | Port/system utilities (`kp`, `fpk`, `gpc`, `adb`, `scrcpy`, etc.). |
| `functions/03-fpath.sh` | Function Paths | `FUNC_DIR=$SSOT/functions`, `fn()`, `ep()`, `hop()`, `sd()`, `cdc()`. |
| `functions/04-openclaw.sh` | OpenClaw | OpenClaw integration (reads `$OP_DIR/*.env`). |
| `functions/05-pathx.sh` | PATH | `05-project.sh` runners. |
| `functions/07-wtf.sh` | WTF | Diagnostic tool. |
| `functions/08.hermes.sh` | Hermes (functions) | Hermes integration. ⚠️ Filename uses **dot** `08.hermes.sh`, not dash `08-hermes.sh`. |
| `functions/09-all_block_status.sh` | Block Status | All-block status dashboard. |
| `functions/backup.sh` | Backup | Backup helpers. |
| `functions/clean.sh` | Cleanup | Cleanup helpers. |
| `functions/tools.sh` | Misc tools | General tool functions. |
| `functions/joe-block/entry.sh` ✅ | Block Engine (canonical) | `m()`, `m_random`, `m_animate`, `dashboard()`, `dashboard_array()`, `_blk_source_modules()`. See `.github/instructions/joe-block.instructions.md`. |
| `functions/joe-block/block/*.sh` | Block internal | `utils.sh` (constants), `layout.sh` (dimensions), `theme.sh` (style loader), `renderer.sh` (ASCII), `status.sh` (data providers). |
| `functions/joe-block/styles/block_style.sh` | Block styles | Style definitions (a/b/c/default/random). |
| `tools/safe-edit.sh` | Pre-commit Guard | V4-aware: blocks inline ANSI outside `01-colors.sh`, V2 vars, hardcoded IPs/keys. |
| `tools/ssot-audit.sh` | SSOT Auditor | Detects drift, ANSI, syntax errors across the whole repo. |
| `tools/agent-pre-commit.sh` | Pre-commit Hook | Runs `safe-edit.sh` + `bash -n` on every `.sh` change. |
| `tools/syncctl/syncctl` ✅ | Syncthing CLI (canonical) | `cmd_*()` dispatch, sourced by joe.sh (via `ssot_load` declaration; load happens transitively today). Uses `$SSOT/bootstrap/00-env.sh`, `$SSOT/core/01-colors.sh`. Symlink at `~/.local/bin/syncctl`. See `.github/skills/syncctl/SKILL.md`. |
| `tools/hermes.sh` | Hermes CLI | Hermes wrapper, sourced by `00-fm-loader.sh`. |
| `plugins/block_engine/` ⚠️ | Block Engine (legacy) | **DUPLICATE** of `functions/joe-block/`. Uses legacy `$JOE_ROOT` / `$JOE_PLUGINS` paths. **DO NOT USE** — `functions/joe-block/` is canonical. |
| `plugins/syncctl/` ⚠️ | Syncctl (legacy) | **DUPLICATE** of `tools/syncctl/`. **DO NOT USE** — `tools/syncctl/` is canonical. |
| `plugins/hermes/hermes.sh` | Hermes plugin | Legacy Hermes plugin (sourced by `00.1-function-tools.sh`). |

> **⚠️ SYNCTHING CAVEAT:** `~/bashscripts` is synced via Syncthing across devices.
> After editing files, verify: `bash -n <file>` and (when applicable) run the
> `tools/syncctl/tests/run.sh` test suite. The `plugins/` tree is **legacy and
> pending removal** — do not edit there.

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
# New system utility?       → functions/02-systems.sh
# New project runner?       → functions/05-project.sh
# New OpenClaw function?    → functions/04-openclaw.sh
# New SSH/transfer?         → core/3worlds.sh
# New SSH config helper?    → core/ssh-config.sh
# New auto-install wrapper? → core/ensure.sh
# New file manager feature? → core/bash-manager.sh
```

### ✅ Add new env vars to 00-env.sh
```bash
# If you need a NEW variable that doesn't exist yet,
# add it to bootstrap/00-env.sh in the appropriate section,
# then reference it everywhere else.
```

### ✅ Add new aliases to core/aliases.sh
```bash
# If you need a NEW alias, add it to core/aliases.sh
# organized by category.
```

### ✅ Module Placement Rules (Where to put new files)

| If you need to add... | Put it in... | Why |
|---|---|---|
| New env var / credential / IP / port | `bootstrap/00-env.sh` (in matching section) | SSOT for all env — sourced first by `joe.sh` |
| New color / style code | `core/01-colors.sh` | ONLY file allowed to contain raw `\e[` |
| New SSH / file transfer helper | `core/3worlds.sh` | Uses `NODE_*` / `ST_KEY_*` from `00-env.sh` |
| New SSH config helper (key gen, clipboard) | `core/ssh-config.sh` | Cross-platform SSH helper |
| New auto-install wrapper | `core/ensure.sh` | `ensure_ <cmd> [pkg]` for pkg/apt |
| New alias | `core/aliases.sh` | Sourced via `ssot_load` declaration |
| New prompt / theme | `core/theme.sh` | Needs colors loaded |
| New general function module | `functions/NN-name.sh` | Glob-loaded by `joe.sh` after `ssot_load` |
| New file manager feature | `core/bash-manager.sh` | Self-bootstrapping SSOT loaders |
| New block engine status provider / style | `functions/joe-block/block/status.sh` or `functions/joe-block/styles/block_style.sh` | See `.github/instructions/joe-block.instructions.md` |
| New AI profile / OpenCode helper | `core/profiles.sh` (extend `ai_profile()`) | The ONLY place that mutates `OPENCODE_*` at runtime |
| New syncctl library function | `tools/syncctl/lib/<module>.sh` | Guard with plain `_SYNCCTL_*_LOADED=1` (NEVER `export`) |

> **⚠️ HARD RULE:** Do NOT add `source` calls inside `00-env.sh` for files
> that depend on it. Do NOT add `source` calls in `~/.bashrc` other than
> `joe.sh`. **`joe.sh` is the ONLY source orchestrator.**

> **⚠️ REFACTOR-IN-PROGRESS:** `joe.sh` currently sources only
> `bootstrap/00-env.sh` and `core/01-colors.sh` directly. Everything else
> loads transitively (mostly via `functions/00-fm-loader.sh`). When adding
> a new top-level module:
> 1. Drop the file in the right directory (table above).
> 2. Add it to the `ssot_load()` `load_files` array (joe.sh ~line 138).
> 3. Make sure `functions/00-fm-loader.sh` or `00.1-function-tools.sh`
>    sources it transitively OR it gets picked up by `functions/*.sh` glob.

> **⚠️ OpenCode Key Rotation Workflow:** When an API key expires:
> 1. Update `$OC_KEY_<PROFILE>` in `bootstrap/00-env.sh`.
> 2. Default aliases (`$OPENCODE_GO_API_KEY` etc.) auto-update on next shell.
> 3. Run `pf <profile>` to refresh runtime if shell already open.
> 4. NEVER edit keys in `joe.sh` directly — `ai_profile()` lives in `core/profiles.sh`.

> **⚠️ LEGACY PLUGIN TREES:** `plugins/block_engine/` and `plugins/syncctl/`
> are **stale duplicates** of the canonical `functions/joe-block/` and
> `tools/syncctl/` respectively. They use legacy `$JOE_ROOT` paths. New code
> MUST go to the canonical location. Do not modify the `plugins/` trees until
> they are deleted.

## 4. 📋 Pre-Flight Checklist (Before Writing Code)

Before creating or modifying any script, you MUST:

1. **Search first** — Use `Grep` to check if a variable/function already exists:
   - `grep -r "VARIABLE_NAME" ~/bashscripts/`
   - `grep -r "function_name()" ~/bashscripts/`
2. **Check `bootstrap/00-env.sh`** — Is the path/IP/port/credential already defined there?
3. **Check `core/01-colors.sh`** — Is the color/style already defined there?
4. **Check `core/aliases.sh`** — Is the alias already defined there?
5. **Check `functions/*.sh` / `core/bash-manager.sh` / `core/3worlds.sh`** — Does the function already exist?
6. **Use existing vars** — If it exists, USE it. If it doesn't, ADD it to the correct SSOT file first.
7. **Confirm path** — Prefer `$SSOT` (canonical) over `$JOE_ROOT` (legacy).

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
- `functions/joe-block/entry.sh` (Block Engine) is designed for both **bash** and **zsh**
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

### 7. **`joe.sh` Refactor in Progress (2026-08-23)** — READ BEFORE EDITING
The recent `joe.sh` refactor introduced a **`ssot_load()` declared loader**,
but the loader currently only **prints** the file list — it does NOT actually
source them. Files still load transitively:

- `bootstrap/00-env.sh` + `core/01-colors.sh` → explicitly sourced by `joe.sh`
- `core/{aliases,profiles,theme,3worlds,ssh-config}.sh` → loaded when first
  invoked (`fm` → `core/bash-manager.sh`; `tm/tw/wsl` → `core/3worlds.sh`;
  `pf` → `core/profiles.sh`; `syncctl` → `tools/syncctl/syncctl`)
- `functions/*.sh` → glob-loaded by `joe.sh` (`functions/NN-*.sh` alphabetical)
- `tools/syncctl/syncctl` → loaded transitively when `syncctl` is first called

**Implications:**
- Adding a new file to `ssot_load()`'s `load_files` array does **not** make
  it available — you must also ensure transitive loaders pick it up.
- Do NOT add code that assumes `core/aliases.sh` is sourced at boot — call
  it lazily or add the explicit source to `joe.sh`.

### 8. **Dual Path System: `$SSOT` vs `$JOE_ROOT`**
Post-refactor, there are TWO coexisting path conventions:
- `$SSOT` / `$SCRIPTS_PATH` / `$COLOR_PATH` — set by `joe.sh` Step 1 case
  (canonical in new code)
- `$JOE_ROOT` / `$JOE_CORE` / `$JOE_PLUGINS` / `$JOE_TOOLS` — set by
  `bootstrap/setup.sh` for legacy compat (still used by `plugins/block_engine/`,
  `plugins/syncctl/`, `modules/ai_block.sh`, `tools/mumu-debug.sh`)

**Rule:** New code MUST use `$SSOT` (or its aliases). Existing legacy code
keeps `$JOE_ROOT` until migration. The two values usually resolve to the
same path, but `$JOE_PLUGINS` points to the legacy `plugins/` tree.

### 9. **Legacy `plugins/` Directory**
- `plugins/block_engine/` is a STALE duplicate of `functions/joe-block/`
- `plugins/syncctl/` is a STALE duplicate of `tools/syncctl/`
- `plugins/hermes/hermes.sh` is legacy
- DO NOT add new code to `plugins/`. Plan to delete the duplicates.

### 10. **Powerlevel10k Instant Prompt**
ANY stdout from `joe.sh` init (CRLF notice, sshd/ssh-agent messages, pf
output) **breaks** p10k instant prompt and triggers a multi-line warning.
All init-time notifications MUST go to **stderr** (use `>&2`). See
`joe.sh` for examples.

### 11. **Renamed/Moved Files (2026-08-23)**
- `core/02-aliases.sh` → `core/aliases.sh` (header comment not yet updated)
- `functions/11-bash-manager.sh` → `core/bash-manager.sh`
- New: `core/ssh-config.sh`, `core/ensure.sh`
- `functions/08.hermes.sh` (note the dot, not `08-hermes.sh`)

If you see stale references to old names, fix them in place.

## 5. 🗂️ Adding New Content — Where Does It Go?

| What you're adding | Where it goes |
|---|---|
| New environment variable / path / IP / credential | `bootstrap/00-env.sh` (in the correct section) |
| New color or style | `core/01-colors.sh` |
| New alias | `core/aliases.sh` (in the correct category) |
| New system/network utility function | `functions/02-systems.sh` |
| New project runner / dashboard function | `functions/05-project.sh` |
| New OpenClaw function | `functions/04-openclaw.sh` |
| New SSH connection / file transfer | `core/3worlds.sh` |
| New SSH config helper (key gen, clipboard) | `core/ssh-config.sh` |
| New auto-install wrapper | `core/ensure.sh` |
| New File Manager feature | `core/bash-manager.sh` (was `functions/11-bash-manager.sh`) |
| New prompt/theme element | `core/theme.sh` |
| New function module file | `functions/NN-name.sh` + add to `ssot_load()`'s `load_files` array (joe.sh ~line 138) |
| New block engine status / style | `functions/joe-block/block/status.sh` or `functions/joe-block/styles/block_style.sh` |

## 6. 🔑 Key Variables Quick Reference

### Core Paths (from `joe.sh` Step 1 case + global vars)
- `JOE_ENV` — Current environment: `TERMUX` | `MUMU` | `WSL` | `GIT-BASH` (set from `MY_DEVICE` or `.bashrc`/`.zshrc`)
- `SSOT` — **Canonical repo root** (e.g. `$HOME/bashscripts`) — set per-env in joe.sh case
- `SCRIPTS_PATH` — Alias of `$SSOT`
- `COLOR_PATH` — Alias of `$SSOT`
- `DASHBOARD_DIR` — Dashboard project path (per-env)
- `OBSIDIAN_VAULT` — Obsidian vault path (per-env)
- `home` — Logical home (differs from `$HOME` on GIT-BASH)
- `nexus_vault` — Path to `~/nexus_vault/` (linked knowledge SSOT — see §8)
- `MAIN_SYNC_DIR` / `msync` — Syncthing-main sync folder
- `OP_DIR` — `${HOME}` (set after the case statement)

### Per-env Home Aliases (from `joe.sh` Step 1)
- `hpc` — Windows home (`/mnt/c/Users/User` on WSL; `$HOME` on GIT-BASH; **unset on TERMUX/MUMU**)
- `htm` — Termux home (`/data/data/com.termux/files/home`); also exposed globally after the case
- `hwsl` — WSL home (`$HOME` on WSL; `//wsl.localhost/Ubuntu/home/usercivenz` on GIT-BASH)

### SSH Ports (from `joe.sh` + `00-env.sh`)
- `SSH_PORT` — Current env's sshd port (8022 TERMUX / 8020 MUMU / 22 WSL / 2222 GIT-BASH)
- `SSH_MUMU_PORT=8020`, `SSH_TERMUX_PORT=8022`, `SSH_WSL_PORT=22`, `SSH_WIN_PORT=22` (always exported)

### Derived Paths (from `00-env.sh`)
- `oppc` — `$hpc/openclaw` (only when `hpc` set)
- `dpc` / `dtpc` — `$hpc/Desktop` (compat pair, `dtpc` is alias for `dpc`)
- `hmp` — `${HERMES_DIR:-$HOME/.hermes}`
- `HERMES_LOG_DIR` — `${HERMES_DIR}/logs`
- `HERMES_DIR`, `PYTHON_VENV`, `SDCARD_PATH`, `NODE_HOST`, `WIN_PATH` — per-env
- `ENGINES_DIR` — `$DASHBOARD_DIR/api/engines`
- `alpha` / `ALPHA_DIR` — `$msync/alpha-workspace`
- `storage` — `/storage/emulated/0/`
- `profile` — Default AI profile (currently `mom`)

### Network (from `00-env.sh`)
- `WINDOWS_IP`, `WINDOWS_USER`
- `WSL_IP`, `WSL_USER`
- `TERMUX_IP`, `TERMUX_USER`, `TERMUX_PORT`
- `DEBIAN_IP`, `DEBIAN_USER`, `DEBIAN_PORT`

### `joe.sh` Global Helpers
- `pp()` — Smart reload: sources `~/.zshrc` for TERMUX/MUMU, `~/.bashrc` for WSL/GIT-BASH; prints status (cn + JOE_ENV). Calls `cn` so `01-colors.sh` must be loaded first.
- `MY_DEVICE` — External override for `JOE_ENV` (read in Step 0).

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
| Service patterns (openclaw, syncthing) | `~/nexus_vault/knowledge/wsl-services` | `functions/04-openclaw.sh`, `core/3worlds.sh` |
| Shell function patterns (getopts, OPTIND) | `~/nexus_vault/knowledge/bashscripts` | (this file + `functions/*.sh`) |
| Port map (syncthing, tailscale IPs) | `~/nexus_vault/knowledge/ports` | `bootstrap/00-env.sh` |
| Color definitions | `~/nexus_vault/knowledge/bashscripts` | `core/01-colors.sh` |
| Tailscale topology | `~/nexus_vault/knowledge/tailscale` | `bootstrap/00-env.sh` (`WINDOWS_IP`, `WSL_IP`, etc.) |
| SSH daemon / ssh-agent auto-start | `~/nexus_vault/knowledge/ssh-agent` | `joe.sh` (Step ssh-agent/sshd block) |

**Daily logs** in `~/nexus_vault/memory/daily/` track work sessions. Check today's log before making changes — recent context matters.

## 9. � Syncctl — Syncthing Ownership Controller

> **syncctl** manages single-master ownership for the `bashscripts` Syncthing folder
> across WSL/Windows/Termux/MuMu. Enforces: 1 Master (sendonly) + N replicas (receiveonly).

### Architecture
- **Canonical location:** `tools/syncctl/syncctl` (with `lib/` modules). Legacy duplicate at `plugins/syncctl/` — DO NOT USE.
- **SSOT for config:** `bootstrap/00-env.sh` owns `NODE_*_ST_ID`, `ST_KEY_*`, `NODE_*_ST_URL`
- **SSOT for folder ID:** `tools/syncctl/lib/config.sh` sets `SYNCCTL_FOLDER_ID=qrkzm-pecck` (Syncthing ID, NOT label)
- **Declared by joe.sh** in `ssot_load()` `load_files` array (currently print-only, see §4.3 #7) — also loaded transitively on first `syncctl` invocation
- **Sourced as functions only** — `main "$@"` guarded by `BASH_SOURCE[0] == $0`
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
> Canonical location: **`functions/joe-block/`**. The duplicate at
> `plugins/block_engine/` is legacy — do NOT modify it.
> For detailed instructions, see `.github/instructions/joe-block.instructions.md`.

### Architecture (Rows → Layout → Theme → Renderer)
```
functions/joe-block/entry.sh (m/dashboard_array)
    ↓
block/status.sh (data providers: status_new, op_profile)
    ↓
block/layout.sh (calculates dimensions: _LAYOUT[])
    ↓
block/theme.sh (loads style from styles/block_style.sh: _THEME[])
    ↓
block/renderer.sh (draws borders, rows, separators)
```

### Quick Reference
```bash
m a                    # Dashboard with style "a"
m b                    # Dashboard with style "b"
m_random               # Random style
m_animate              # Animated style rotation
dashboard_array "${ROWS[@]}"  # Render from array
```

### Key Files (canonical — at `functions/joe-block/`)
| File | Purpose |
|------|---------|
| `functions/joe-block/entry.sh` | Public API (m, dashboard, dashboard_array) |
| `functions/joe-block/block/status.sh` | Data providers (status_new, op_profile) |
| `functions/joe-block/block/layout.sh` | Dimension calculations |
| `functions/joe-block/block/theme.sh` | Style loading and color compilation |
| `functions/joe-block/block/renderer.sh` | ASCII rendering |
| `functions/joe-block/styles/block_style.sh` | Style definitions (a/b/c/default/random) |

### Sourcing
- Auto-sourced by `functions/00-fm-loader.sh` (joe.sh → ssot_load → fm-loader → entry.sh).
- Today, `joe.sh`'s `ssot_load()` only **declares** the path but does not actually source it
  (see ⚠️ in §3). The transitive load via `00-fm-loader.sh` is what makes it work.

### SSOT Compliance
- Never hardcode colors — use helpers from `01-colors.sh`
- Use `set_ <var> <value>` in `styles/block_style.sh` to populate `_THEME` and `_LAYOUT`
- Cross-shell support: avoid bash-specific features in public API
- Idempotent sourcing: modules in `block/` are sourced automatically by `entry.sh`

## 9.2 🤖 Hermes AI Integration

> **Hermes** provides AI-powered assistance within the terminal.
> Canonical: `tools/hermes.sh` + `functions/08.hermes.sh`.
> Legacy: `plugins/hermes/hermes.sh` (do not edit).

### Quick Reference
```bash
hermes                  # Launch Hermes AI assistant
hermes_load             # Source Hermes (from 00-fm-loader.sh)
```

### Key Files
| File | Purpose |
|------|---------|
| `tools/hermes.sh` | Hermes CLI wrapper (sourced by 00-fm-loader.sh) |
| `functions/08.hermes.sh` | Hermes function module (note the dot in filename) |
| `plugins/hermes/hermes.sh` | ⚠️ Legacy duplicate — DO NOT edit |
| `functions/00.1-function-tools.sh` | Shared helpers (sources hermes helpers) |

### SSOT Compliance
- Hermes config is in `bootstrap/00-env.sh` (`$HERMES_DIR`, `$hmp`, `$HERMES_LOG_DIR`)
- Source via `tools/hermes.sh` (canonical) or `plugins/hermes/hermes.sh` (legacy)
- Do not redefine Hermes functions in other files

## 9.3 📁 File Manager (fm/xfm)

> **File Manager** provides ls/cp/mv/tree/ssh/push/pull operations.
> Canonical location: **`core/bash-manager.sh`** (moved from `functions/11-bash-manager.sh` 2026-08-23).

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
| `core/bash-manager.sh` ✅ | Main file manager (fm/xfm) — self-bootstrapping |
| `functions/00-fm-loader.sh` | FM bootstrapper (`fm()` command, sources bash-manager.sh on first call) |

### Sourcing
- `fm` checks `$BASH_MANAGER`; if unset, sources `$SSOT/core/bash-manager.sh` first
  (which itself auto-loads `01-colors.sh` + `00-env.sh` if needed). Then runs `fm learn on`
  + `fm "$@"`. So the first `fm` invocation in a fresh shell lazily loads it.

### SSOT Compliance
- Uses `$SSOT/core/01-colors.sh` for color output (via guard `command -v c`)
- Uses `$SSOT/bootstrap/00-env.sh` for environment variables (via guard `$TERMUX_IP`)
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
| `core/3worlds.sh` | SSH/transfer functions (tm/tw/wsl/push/pull) — declared in joe.sh `ssot_load` |
| `core/ssh-config.sh` | SSH config helpers (cb_copy / ssh_kgen / ssh_kadd) — NEW 2026-08-23 |

### SSOT Compliance
- Network config is in `bootstrap/00-env.sh` (`$WINDOWS_IP`, `$TERMUX_IP`, etc.)
- SSH keys are in `bootstrap/00-env.sh` (`$ST_KEY_*`)
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
| `core/01-colors.sh` | Color engine V3/V4 (c/cn/color/ctab/hline/rc) — sourced directly by joe.sh |

### SSOT Compliance
- **ONLY** `01-colors.sh` is allowed to contain raw `\e[` or `\033[`
- All other files MUST use helpers: `c`, `cn`, `color`, `ctab`, `hline`, `rc`
- Enforcement: `tools/safe-edit.sh` + `tools/ssot-audit.sh` will FAIL any file with inline ANSI outside `01-colors.sh`
- See Color System V3/V4 Quick Reference in Section 2

## 9.6 🔍 Environment Detection (joe.sh)

> **joe.sh** detects the current environment and sets `JOE_ENV`.
> Located at `joe.sh` — Step 0 reads `MY_DEVICE` (set externally), Step 1 case
> statement sets all per-env vars.

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

# Smart reload (defined in joe.sh)
pp                      # reloads .zshrc on TERMUX/MUMU, .bashrc on WSL/GIT-BASH
```

### Key Files
| File | Purpose |
|------|---------|
| `joe.sh` | Main entry point, env detection, `pp()` reload helper, `ssot_load()` declared loader |

### SSOT Compliance
- `JOE_ENV` is set by `joe.sh` Step 0/1 — do not override it (only `MY_DEVICE` upstream may set it)
- Environment detection is centralized in `joe.sh` — do not duplicate in other files
- Use `$JOE_ENV` for environment branching, not hardcoded checks
- ssh-agent auto-start: gated by `SSH_AUTH_SOCK` + `ssh-add -l`; adds `~/.ssh/id_ed25519` if present
- sshd auto-start: WSL uses `service ssh`; TERMUX/MUMU uses `sshd -p $SSH_PORT` (guarded by `pgrep -f "sshd.*-p.*${SSH_PORT}"`); all output to stderr (p10k compat)

## 9.7 🚀 Boot Sequence (joe.sh)

> **joe.sh** is the ONLY entry point for loading the bashscripts ecosystem.
> Located at `joe.sh`. As of 2026-08-23, the boot sequence uses `ssot_load()` for
> declared loader pattern (see ⚠️ note below).

### Quick Reference (current boot flow)
```bash
source ~/.bashrc or ~/.zshrc
  └─ source joe.sh                    [BOOSTER — only entry point]
       ├─ Step 0:    JOE_ENV fallback  ← read MY_DEVICE if exported; else trust JOE_ENV
       ├─ Step 1:    case JOE_ENV       ← export SSOT, DASHBOARD_DIR, hpc/htm/hwsl,
       │                                   OBSIDIAN_VAULT, home, nexus_vault,
       │                                   MAIN_SYNC_DIR, SSH_PORT, PYTHON_VENV
       │             globals (after case) ← SCRIPTS_PATH=$SSOT, COLOR_PATH=$SSOT,
       │                                     msync, htm, OP_DIR
       │             export SSH_MUMU_PORT=8020, SSH_TERMUX_PORT=8022,
       │                     SSH_WSL_PORT=22, SSH_WIN_PORT=22
       ├─ Step 1.5:  CRLF SELF-HEAL     ← sed CRLF→LF on $SSOT/**/*.sh; stderr-only
       │
       ├─ [ -f ... ] && source $SSOT/bootstrap/00-env.sh  ← env vars, paths, keys
       ├─ [ -f ... ] && source $SSOT/core/01-colors.sh    ← c/cn/color, ctab, hline, rc
       │
       ├─ auto-start ssh-agent          ← if SSH_AUTH_SOCK unset or ssh-add -l fails
       ├─ auto-start sshd               ← WSL: service ssh
       │                                  TERMUX/MUMU: sshd -p $SSH_PORT
       │                                  (pgrep -f "sshd.*-p.*${SSH_PORT}" check)
       │
       ├─ ssot_load "1"                 ← ⚠️ DECLARED LOADER (currently print-only!)
       │     load_files = (
       │       core/ssh-config.sh      ─┐
       │       core/3worlds.sh           │ declared but NOT actually
       │       core/aliases.sh           │ sourced today — files load
       │       core/profiles.sh          │ transitively via 00-fm-loader.sh
       │       core/theme.sh             │ or via first call to `fm`/`tm`/`tw`/`syncctl`
       │       functions/*.sh           │
       │       tools/syncctl/syncctl   ─┘
       │     )
       │
       ├─ startup tasks (per JOE_ENV)
       │     TERMUX|MUMU → rc_delete >&2
       │     WSL         → syncthing_auto
       │     GIT-BASH    → (no-op)
       │
       ├─ pf mom                        ← seed OpenCode API keys (ai_profile in core/profiles.sh)
       └─ set +u                        ← ble.sh restores set -u per cmd
```

### Key Files
| File | Purpose |
|------|---------|
| `joe.sh` | Main entry point, boot orchestrator, `pp()` reload, `ssot_load()` declaration |
| `bootstrap/00-env.sh` | Only env file explicitly sourced by joe.sh |
| `core/01-colors.sh` | Only colors file explicitly sourced by joe.sh |
| `functions/00-fm-loader.sh` | Transitive loader for joe-block + tools/{hermes,merge,wtf,ai_block} |

### SSOT Compliance
- `joe.sh` is the ONLY source orchestrator — do not add `source` calls in `~/.bashrc` other than `joe.sh`
- Do NOT add `source` calls inside `00-env.sh` for files that depend on it
- Source order matters — follow the boot sequence exactly
- **Init-time console output MUST go to stderr** (CRLF notice, ssh-agent/sshd status)
  to preserve Powerlevel10k instant prompt

## 10. 📋 Quick Reference for AI Agents

### Testing Changes
```bash
# Reload config after changes
source ~/bashscripts/joe.sh      # full reload
pp                                # smart reload (joe.sh helper)

# Test specific function
source "$SSOT/functions/02-systems.sh"
fp 8022                          # Test port check

# Test color function (requires $SSOT)
source "$SSOT/core/01-colors.sh"
cn lg b "Test message"           # Should show light green bold (cn = จบบรรทัด)
```

### Common Pitfalls
1. **Port conflicts** — Always check with `fp <port>` before starting services
2. **SSH timeouts** — Use `tm` for Termux SSH, `tw` for Windows SSH
3. **Python venv** — Always `source $PYTHON_VENV` before running Python scripts
4. **JOE_ENV detection** — Check `$JOE_ENV` before running environment-specific code
5. **`MY_DEVICE` overrides `JOE_ENV`** — Set externally before `source joe.sh`
6. **`ssot_load` is declared, not active** — Most core files load lazily
7. **`plugins/` is legacy** — Use `functions/joe-block/` and `tools/syncctl/`

### File Naming Conventions
- `00-`, `01-`, `02-` prefixes = load order priority (functions/, core/)
- `functions/*.sh` = modular function files (glob-loaded)
- `tools/*.sh` = utility scripts (NOT auto-loaded; sourced via 00-fm-loader.sh)
- `*shbk` or `*bk` = backup files (can be ignored)
- ⚠️ `functions/08.hermes.sh` uses a DOT in the name (not `08-hermes.sh`)

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
ssh_kgen <machine>  # Generate ed25519 key for a machine (core/ssh-config.sh)
ssh_kadd             # Add public key to authorized_keys
```

## 11. 🔄 Maintenance Notes

### Syncthing Integration
- The repo is synced across devices via Syncthing
- SSOT variables for Syncthing are in `bootstrap/00-env.sh` (`NODE_*_ST_ID`, `ST_KEY_*`)
- Daily logs in `~/nexus_vault/memory/daily/` track changes

### Backup Strategy
- `tools/*shbk` files = backup copies (safe to ignore)
- Keep backups minimal — prefer git history over file copies

### Adding New Features
1. Check if similar functionality exists (`grep` first!)
2. Add new env vars to `bootstrap/00-env.sh`
3. Add new functions to appropriate `functions/*.sh` file (or `core/bash-manager.sh` for fm, `core/3worlds.sh` for SSH, etc.)
4. Add new aliases to `core/aliases.sh`
5. Register the file in `joe.sh`'s `ssot_load()` `load_files` array (joe.sh ~line 138) AND ensure a transitive loader picks it up
6. Test with `source ~/bashscripts/joe.sh` and run `bash -n <file>` before committing
