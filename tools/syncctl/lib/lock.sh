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

source "${SYNCCTL_LIB_DIR:-$(dirname "$0")}/config.sh"

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

    # Lock exists — reclaim if the holder process is dead (crash/kill left a stale lock)
    if _lock_is_stale; then
        echo "syncctl: stale lock (pid $(lock_holder_pid)) — reclaiming" >&2
        rm -rf "$SYNCCTL_LOCK_FILE.lockdir" 2>/dev/null
        if mkdir "$SYNCCTL_LOCK_FILE.lockdir" 2>/dev/null; then
            echo $$ > "$SYNCCTL_LOCK_FILE.lockdir/pid"
            _SYNCCTL_LOCK_DIR="$SYNCCTL_LOCK_FILE.lockdir"
            return 0
        fi
    fi

    # Already locked (live holder)
    if [[ "$mode" == "wait" ]]; then
        # Poll for release (simple, not optimal but works)
        local i=0
        while ! mkdir "$SYNCCTL_LOCK_FILE.lockdir" 2>/dev/null; do
            # Holder may have died mid-wait → reclaim and retry
            if _lock_is_stale; then
                rm -rf "$SYNCCTL_LOCK_FILE.lockdir" 2>/dev/null
                continue
            fi
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

# A lock is stale when its holder pid is dead or missing.
# Conservative: if the pid file is absent we treat the lock as orphaned (stale);
# if the pid is alive (or a zombie) we treat the lock as held.
_lock_is_stale() {
    local lockdir="$SYNCCTL_LOCK_FILE.lockdir" pid=""
    [[ -d "$lockdir" ]] || return 1          # no lock at all → not stale
    [[ -f "$lockdir/pid" ]] || return 0      # lock w/o pid file → orphaned → stale
    pid="$(cat "$lockdir/pid" 2>/dev/null || true)"
    [[ -n "$pid" ]] || return 0              # empty pid file → stale
    # Linux (Termux/WSL): /proc is authoritative — it exists even for
    # processes owned by other users (kill -0 would EPERM and look dead).
    if [[ -d "/proc" ]]; then
        [[ -d "/proc/$pid" ]] && return 1 || return 0
    fi
    # No /proc (Git-Bash/MSYS): fall back to kill -0, treating EPERM as alive.
    if kill -0 "$pid" 2>/dev/null; then
        return 1
    fi
    kill -0 "$pid" 2>&1 | grep -qi 'permission\|not permitted' && return 1
    return 0
}

# Release the lock.
# `lock_release force` also removes a lock held by ANOTHER process —
# used by `syncctl unlock` (explicit admin command). Plain lock_release
# (e.g. EXIT trap) only removes a lock THIS process acquired, so a failed
# acquire can never delete a live lock.
lock_release() {
    local force="${1:-}"
    local _target=""
    if [[ -n "${_SYNCCTL_LOCK_DIR:-}" ]]; then
        _target="$_SYNCCTL_LOCK_DIR"
    elif [[ "$force" == "force" && -n "${SYNCCTL_LOCK_FILE:-}" ]]; then
        _target="${SYNCCTL_LOCK_FILE}.lockdir"
    fi
    [[ -n "$_target" ]] && rm -rf "$_target" 2>/dev/null
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
