#!/bin/bash
# ============================================================
# syncctl/lib/config.sh — Device registry + paths + jq helper
# ============================================================
# Reuses SSOT from ~/bashscripts/00-env.sh (NODE_*, ST_KEY_*)
# Adds syncctl-specific config (paths, version, defaults)
# ============================================================

# Guard: prevent double-source (no export — leaks to child processes)
[[ -n "${_SYNCCTL_CONFIG_LOADED:-}" ]] && return 0
_SYNCCTL_CONFIG_LOADED=1

# ──────────────────────────────────────────────────────────
# Paths
# ──────────────────────────────────────────────────────────
export SYNCCTL_HOME="${SYNCCTL_HOME:-$HOME/.local/share/syncctl}"
export SYNCCTL_STATE="$SYNCCTL_HOME/state.json"
export SYNCCTL_LOCK_FILE="$SYNCCTL_HOME/syncctl.lock"
export SYNCCTL_AUDIT_LOG="$SYNCCTL_HOME/audit.log"
export SYNCCTL_CHECKPOINT_DIR="$SYNCCTL_HOME/checkpoints"
export SYNCCTL_CONFLICT_ARCHIVE="$SYNCCTL_HOME/conflicts"
export SYNCCTL_LOCAL_MASTER_FILE="$SYNCCTL_HOME/master"

# Synced .syncctl/ directory inside the controlled folder
export SYNCCTL_FOLDER_ROOT="${SYNCCTL_FOLDER_ROOT:-${SSOT:-$HOME/bashscripts}}"
export SYNCCTL_SYNCED_MASTER_DIR="$SYNCCTL_FOLDER_ROOT/.syncctl"
export SYNCCTL_SYNCED_MASTER_FILE="$SYNCCTL_SYNCED_MASTER_DIR/master"

# Folder ID in Syncthing (default: bashscripts folder)
# NOTE: This is the Syncthing folder ID, NOT the display label.
# Use `syncctl doctor` or Syncthing API to verify.
export SYNCCTL_FOLDER_ID="${SYNCCTL_FOLDER_ID:-qrkzm-pecck}"

# ──────────────────────────────────────────────────────────
# Device registry
# ──────────────────────────────────────────────────────────
declare -gA SYNCCTL_DEVICES=()

[[ -n "${NODE_WSL_ST_ID:-}" ]]    && SYNCCTL_DEVICES[wsl]="$NODE_WSL_ST_ID"
[[ -n "${NODE_WIN_ST_ID:-}" ]]    && SYNCCTL_DEVICES[windows]="$NODE_WIN_ST_ID"
[[ -n "${NODE_TERMUX_ST_ID:-}" ]] && SYNCCTL_DEVICES[termux]="$NODE_TERMUX_ST_ID"
[[ -n "${NODE_MUMU_ST_ID:-}" ]]   && SYNCCTL_DEVICES[mumu]="$NODE_MUMU_ST_ID"

declare -gA SYNCCTL_API_URLS=()
[[ -n "${NODE_WSL_ST_URL:-}" ]]    && SYNCCTL_API_URLS[wsl]="$NODE_WSL_ST_URL"
[[ -n "${NODE_WIN_ST_URL:-}" ]]    && SYNCCTL_API_URLS[windows]="$NODE_WIN_ST_URL"
[[ -n "${NODE_TERMUX_ST_URL:-}" ]] && SYNCCTL_API_URLS[termux]="$NODE_TERMUX_ST_URL"
[[ -n "${NODE_MUMU_ST_URL:-}" ]]   && SYNCCTL_API_URLS[mumu]="$NODE_MUMU_ST_URL"

declare -gA SYNCCTL_API_KEYS=()
[[ -n "${ST_KEY_WSL:-}" ]]    && SYNCCTL_API_KEYS[wsl]="$ST_KEY_WSL"
[[ -n "${ST_KEY_WIN:-}" ]]    && SYNCCTL_API_KEYS[windows]="$ST_KEY_WIN"
[[ -n "${ST_KEY_TERMUX:-}" ]] && SYNCCTL_API_KEYS[termux]="$ST_KEY_TERMUX"
[[ -n "${ST_KEY_MUMU:-}" ]]   && SYNCCTL_API_KEYS[mumu]="$ST_KEY_MUMU"

case "${JOE_ENV:-}" in
    WSL)      export SYNCCTL_LOCAL_DEVICE="wsl" ;;
    GIT-BASH) export SYNCCTL_LOCAL_DEVICE="windows" ;;
    TERMUX)   export SYNCCTL_LOCAL_DEVICE="termux" ;;
    MUMU)     export SYNCCTL_LOCAL_DEVICE="mumu" ;;
    *)        export SYNCCTL_LOCAL_DEVICE="unknown" ;;
esac

export SYNCCTL_LOCAL_API_URL="${SYNCCTL_API_URLS[$SYNCCTL_LOCAL_DEVICE]:-}"
export SYNCCTL_LOCAL_API_KEY="${SYNCCTL_API_KEYS[$SYNCCTL_LOCAL_DEVICE]:-}"

# ──────────────────────────────────────────────────────────
# Timeout / retry defaults
# ──────────────────────────────────────────────────────────
export SYNCCTL_API_TIMEOUT="${SYNCCTL_API_TIMEOUT:-10}"
export SYNCCTL_API_RETRY="${SYNCCTL_API_RETRY:-2}"
export SYNCCTL_INSYNC_TIMEOUT="${SYNCCTL_INSYNC_TIMEOUT:-60}"
export SYNCCTL_HANDOVER_STALE_TIMEOUT="${SYNCCTL_HANDOVER_STALE_TIMEOUT:-300}"

# ──────────────────────────────────────────────────────────
# Portable JQ Helper (uses system jq or python3 fallback)
# ──────────────────────────────────────────────────────────
syncctl_jq() {
    if command -v jq >/dev/null 2>&1; then
        jq "$@"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c '
import sys, json, select

args = sys.argv[1:]
raw = ""
if select.select([sys.stdin], [], [], 0.05)[0]:
    raw = sys.stdin.read()

try:
    data = json.loads(raw) if raw.strip() else {}
except Exception:
    data = {}

if "-n" in args and not any(a.startswith(".") for a in args):
    res = {}
    i = 0
    while i < len(args):
        if args[i] == "--arg" and i + 2 < len(args):
            res[args[i+1]] = args[i+2]
            i += 3
        elif args[i] == "--argjson" and i + 2 < len(args):
            try:
                res[args[i+1]] = json.loads(args[i+2])
            except Exception:
                res[args[i+1]] = args[i+2]
            i += 3
        else:
            i += 1
    print(json.dumps(res, indent=2))
    sys.exit(0)

if not args:
    print(json.dumps(data, indent=2))
    sys.exit(0)

q = args[-1]
if q == ".id":
    print(data.get("id", ""))
elif q == ".result":
    print(data.get("result", ""))
elif q == ".timestamp":
    print(data.get("timestamp", ""))
elif q.startswith(".completion"):
    print(data.get("completion", 0))
elif q.startswith(".type"):
    v = data.get("type", "unknown")
    print(v)
elif "length" in q:
    if isinstance(data, dict):
        total = 0
        for v in data.values():
            if isinstance(v, list): total += len(v)
        print(total)
    elif isinstance(data, list):
        print(len(data))
    else:
        print(0)
else:
    if isinstance(data, dict):
        key = q.lstrip(".").split()[0]
        val = data.get(key, "")
        if isinstance(val, (dict, list)):
            print(json.dumps(val))
        else:
            print(val if val is not None else "")
    else:
        print(json.dumps(data))
' "$@" 2>/dev/null
    else
        echo ""
    fi
}

syncctl_init_paths() {
    mkdir -p "$SYNCCTL_HOME" \
             "$SYNCCTL_CHECKPOINT_DIR" \
             "$SYNCCTL_CONFLICT_ARCHIVE"
    [[ -f "$SYNCCTL_AUDIT_LOG" ]] || : > "$SYNCCTL_AUDIT_LOG"
}

syncctl_list_devices() {
    echo "wsl windows termux mumu"
}

syncctl_is_known_device() {
    local dev="$1"
    [[ " wsl windows termux mumu " == *" $dev "* ]]
}

# ──────────────────────────────────────────────────────────
# API lookup helpers (used by api_device)
# ──────────────────────────────────────────────────────────
syncctl_get_api_url() {
    echo "${SYNCCTL_API_URLS[$1]:-}"
}

syncctl_get_api_key() {
    echo "${SYNCCTL_API_KEYS[$1]:-}"
}
