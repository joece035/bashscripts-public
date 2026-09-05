# AGENTS.md — bashscripts

> Compact agent guidance for Joe's cross-platform bash/zsh ecosystem.
> Last verified: 2026-09-05 against actual `joe.sh`, `bootstrap/00-env.sh`, `core/`.

## What This Repo Is

Personal CLI command center running on **Termux, WSL, MuMu, Git Bash** via a single entry point (`joe.sh`) that auto-detects the environment.

**SSOT (Single Source of Truth):** Each domain has ONE canonical file. Never redefine what already exists.

## Critical Path Rules

| Variable | Status | Set by |
|----------|--------|--------|
| `$SSOT` | **Canonical** — use this everywhere | `joe.sh` Step 1 case |
| `$SCRIPTS_PATH`, `$COLOR_PATH` | Alias of `$SSOT` | `joe.sh` globals |
| `$JOE_ROOT`, `$JOE_CORE`, `$JOE_PLUGINS` | **Legacy** — still exported but deprecated | `bootstrap/setup.sh` |

**Rule:** New code MUST use `$SSOT`. Legacy `$JOE_ROOT` family exists only for backward compat.

## Environment System

`JOE_ENV` is one of: `TERMUX | MUMU | WSL | GIT-BASH`. Set by `joe.sh` Step 0/1. Override externally via `MY_DEVICE` env var.

## Forbidden Patterns

1. **No raw ANSI escapes outside `core/01-colors.sh`** — Use `c()`, `cn()`, `color()`, `ctab()`, `hline()`, `rc()`. Enforcement: `tools/safe-edit.sh` + `tools/ssot-audit.sh`.

2. **No hardcoded paths/IPs/keys** — Use vars from `bootstrap/00-env.sh` (e.g. `$WINDOWS_IP`, `$TERMUX_IP`, `$DASHBOARD_DIR`).

3. **No redefining existing functions** — Search first: `grep -r "function_name()" ~/bashscripts/`

4. **No new env vars that overlap existing ones** — Check `bootstrap/00-env.sh` first.

5. **No `source` calls in `~/.bashrc` other than `joe.sh`** — `joe.sh` is the ONLY source orchestrator.

6. **No `source` calls inside `00-env.sh` for files that depend on it.**

7. **No stdout from init-time code** — All boot output MUST go to stderr (`>&2`) or Powerlevel10k instant prompt breaks.

## Boot Sequence (Verified)

```
source joe.sh
  ├─ Step 0: MY_DEVICE → JOE_ENV fallback
  ├─ Step 1: case JOE_ENV → export SSOT, DASHBOARD_DIR, SSH_PORT, etc.
  ├─ Global vars → SCRIPTS_PATH=$SSOT, COLOR_PATH=$SSOT, msync, htm, OP_DIR
  ├─ CRLF self-heal (sed on $SSOT/**/*.sh → stderr only)
  ├─ source bootstrap/00-env.sh    ← env vars, paths, keys
  ├─ source core/01-colors.sh      ← color engine
  ├─ auto-start ssh-agent + sshd
  ├─ ssot_load()                   ← sources core/*, functions/*, tools/syncctl, etc.
  ├─ pf mom                        ← seed AI keys
  └─ set +u
```

`ssot_load()` uses `_check` from `.bash_helper` to source files. It sources: `core/{ssh-config,3worlds,aliases,profiles,theme}.sh`, `functions/*.sh`, `tools/syncctl/syncctl`, `functions/joe-block/entry.sh`, and lesson files.

## Module Placement

| Adding... | Put in... |
|-----------|-----------|
| Env var / credential / IP / port | `bootstrap/00-env.sh` |
| Color / style | `core/01-colors.sh` |
| Alias | `core/aliases.sh` |
| SSH / transfer helper | `core/3worlds.sh` |
| SSH config (key gen, clipboard) | `core/ssh-config.sh` |
| Auto-install wrapper | `core/ensure.sh` |
| System utility function | `functions/02-systems.sh` |
| File manager feature | `core/bash-manager.sh` |
| Prompt / theme | `core/theme.sh` |
| General function module | `functions/NN-name.sh` |
| Block engine status/style | `functions/joe-block/block/status.sh` or `styles/block_style.sh` |
| AI profile changes | `core/profiles.sh` (only place that mutates `OPENCODE_*` at runtime) |
| syncctl library | `tools/syncctl/lib/<module>.sh` |

## Legacy / Do Not Use

- `plugins/block_engine/` — stale duplicate of `functions/joe-block/`
- `plugins/syncctl/` — stale duplicate of `tools/syncctl/`
- `plugins/hermes/hermes.sh` — legacy

## Verification Commands

```bash
bash -n <file>                  # Syntax check (required before commit)
bash tools/safe-edit.sh <file>  # SSOT/V4 ANSI enforcement
bash tools/ssot-audit.sh        # Full repo audit
```

## Pre-Commit Hook

`.github/hooks/pre-commit.json` runs `tools/agent-pre-commit.sh` on every `.sh` edit. Enforces `bash -n` + `safe-edit.sh`. Fix errors before proceeding.

## Color System Quick Reference

```bash
c  202 b "text"       # colored text, no newline
cn 202 b "text"       # colored text + newline
ctab "label" "value"  # table row
hline "-" 50          # horizontal line
rc  b "text"          # random palette
```

**Style codes:** `b`=bold, `d`=dim, `i`=italic, `u`=underline. Combine: `bi`, `bdu`.
**256-color palette:** red=196, green=82, yellow=226, cyan=51, orange=208, purple=141, gray=244.

## Syncthing Caveat

`~/bashscripts` is synced across devices via Syncthing. Edits may be overwritten if another device syncs simultaneously. Always run `bash -n <file>` after editing.

## Cross-Shell Compatibility

`functions/joe-block/entry.sh` is designed for both bash and zsh. Avoid bash-specific features (`[[ ]]`, `${var//pattern/replace}`) in public APIs.

## Related Instruction Files

| File | When to load |
|------|-------------|
| `.github/instructions/joe-block.instructions.md` | Working with `functions/joe-block/` |
| `.github/skills/syncctl/SKILL.md` | Using `syncctl` commands |
| `AGENT.md` | Full architecture reference (1096 lines) |
| `DEPENDENCY_MAP.md` | Module dependency graph |
