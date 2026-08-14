# mumu-debug.sh — MUMU Environment Debugger

## Quick Start

```bash
# From WSL (any machine):
mumu-debug           # Run all checks on remote MUMU
mumu-debug ssh       # Only check SSH connectivity
mumu-debug micro     # Only debug micro editor
mumu-debug zsh       # Only debug zsh shell
mumu-debug --fix     # Run all checks + auto-fix issues
mumu-debug --fix micro  # Fix micro editor issues only
```

## Modules

| Module | Description |
|--------|-------------|
| `env` | Local environment validation (JOE_ENV, Tailscale, SSH keys) |
| `ssh` | SSH connectivity to MUMU (ping, connection, shell) |
| `micro` | Micro editor diagnostics (install, config, plugins, logs) |
| `zsh` | Zsh shell diagnostics (.zshrc syntax, OMZ, p10k) |
| `joe` | Joe scripts validation (bashscripts dir, joe.sh, colors) |
| `sync` | Syncthing connectivity (GUI, API, version) |
| `all` | Run all modules (default) |

## Auto-Fix Mode

```bash
mumu-debug --fix micro   # Install micro if missing, clear corrupted config
mumu-debug --fix zsh     # Install zsh, OMZ, plugins, set as default shell
mumu-debug --fix joe     # Ensure JOE_ENV is set in rc files
mumu-debug --fix all     # Fix everything
```

## Standalone Mode (without joe.sh)

The script works standalone — it has built-in color helpers that activate if `c()` is not available.

## Output Legend

- ✔ **PASS** — Check passed
- ✘ **FAIL** — Critical issue found
- ⚠ **WARN** — Non-critical warning
- 🔧 **FIX** — Auto-fix applied
- ℹ **INFO** — Additional information

## Dependencies

- `ssh` with key-based auth to MUMU
- Tailscale (for MagicDNS resolution)
- Node registry vars in `00-env.sh` (NODE_MUMU_*)
