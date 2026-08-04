#!/bin/bash
# ============================================================
# syncctl/lib/lock.sh — flock-based lock manager
# ============================================================
# Single-process lock to prevent concurrent transfer/init.
# Stored at $SYNCCTL_LOCK_FILE.
#
# Usage:
#   lock_acquire || { echo "locked, abort"; exit 1; }
#   trap 'lock_release' EXIT
#   ...
# ============================================================

# Guard
[[ -n "${_SYNCCTL_LOCK_LOADED:-}" ]] && return 0
_SYNCCTL_LOCK_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# Hold the lock here (so we can release)
_SYNCCTL_LOCK_DIR=""

# Try to acquire. Returns 0 if got it, 1 if held by another.
# Uses mkdir (atomic on Linux) instead of flock — works across processes
# and avoids fd-reuse issues in tests.
# If $1 = "wait" → block until acquired
# If $1 = "nowait" (default) → fail immediately
lock_acquire() {
    local mode="${1:-nowait}"
    syncctl_init_paths

    # mkdir is atomic on Linux: succeeds only if dir doesn't exist
    if mkdir "$SYNCCTL_LOCK_FILE.lockdir" 2>/dev/null; then
        echo $$ > "$SYNCCTL_LOCK_FILE.lockdir/pid"
        _SYNCCTL_LOCK_DIR="$SYNCCTL_LOCK_FILE.lockdir"
        return 0
    fi

    # Already locked
    if [[ "$mode" == "wait" ]]; then
        # Poll for release (simple, not optimal but works)
        local i=0
        while ! mkdir "$SYNCCTL_LOCK_FILE.lockdir" 2>/dev/null; do
            (( i++ ))
            [[ $i -gt 300 ]] && return 1   # 30s timeout
            sleep 0.1 2>/dev/null
        done
        echo $$ > "$SYNCCTL_LOCK_FILE.lockdir/pid"
        _SYNCCTL_LOCK_DIR="$SYNCCTL_LOCK_FILE.lockdir"
        return 0
    fi

    echo "syncctl: another instance is running (lock held)" >&2
    return 1
}

# Release the lock
lock_release() {
    [[ -z "${_SYNCCTL_LOCK_DIR:-}" ]] && return 0
    rm -rf "$_SYNCCTL_LOCK_DIR" 2>/dev/null
    _SYNCCTL_LOCK_DIR=""
    rm -f "$SYNCCTL_LOCK_FILE"
    return 0
}

# Check if lock is held (without acquiring)
lock_is_held() {
    [[ -d "$SYNCCTL_LOCK_FILE.lockdir" ]]
}

# Show who holds the lock
lock_holder_pid() {
    [[ -f "$SYNCCTL_LOCK_FILE.lockdir/pid" ]] || return 0
    cat "$SYNCCTL_LOCK_FILE.lockdir/pid" 2>/dev/null
}
