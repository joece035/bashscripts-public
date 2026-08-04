#!/bin/bash
# ============================================================
# syncctl/lib/checkpoint.sh — Checkpoint engine
# ============================================================
# Pre-condition for any transfer.
# Checks:
#   3.1 Local state
#   3.2 Syncthing sync state
#   3.3 Cluster state (all peers in-sync)
#   3.4 Conflict detection (.sync-conflict-* files)
# Produces:
#   - SYNCCTL_CHECKPOINT_ID  (e.g. "0042")
#   - Audit log entry
#   - $SYNCCTL_CHECKPOINT_DIR/<id>.json
# ============================================================

# Guard
[[ -n "${_SYNCCTL_CHECKPOINT_LOADED:-}" ]] && return 0
_SYNCCTL_CHECKPOINT_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/api.sh"
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"

# Globals set by checkpoint_run()
export SYNCCTL_CHECKPOINT_ID=""
export SYNCCTL_CHECKPOINT_RESULT="fail"   # pass | fail
export SYNCCTL_CHECKPOINT_REASON=""

# ──────────────────────────────────────────────────────────
# Next checkpoint ID: read counter, increment (atomic)
# ──────────────────────────────────────────────────────────
_next_checkpoint_id() {
    local counter_file="$SYNCCTL_HOME/checkpoint.counter"
    local lock_dir="$SYNCCTL_HOME/checkpoint_counter.lock"
    local n=0

    # Atomic spin-lock
    local retries=0
    while ! mkdir "$lock_dir" 2>/dev/null; do
        sleep 0.05 2>/dev/null || sleep 1
        retries=$((retries + 1))
        if (( retries > 50 )); then
            rm -rf "$lock_dir" 2>/dev/null || true
        fi
    done

    if [[ -f "$counter_file" ]]; then
        n="$(<"$counter_file")"
    fi
    n=$(( n + 1 ))
    printf '%s' "$n" > "$counter_file"
    rm -rf "$lock_dir" 2>/dev/null
    printf '%04d' "$n"
}

check_local_state() {
    local conflicts
    conflicts="$(find "$SYNCCTL_FOLDER_ROOT" -name '*.sync-conflict-*' -type f 2>/dev/null | head -5)"
    if [[ -n "$conflicts" ]]; then
        SYNCCTL_CHECKPOINT_REASON="local conflict files: $(echo "$conflicts" | wc -l)"
        return 1
    fi
    return 0
}

check_cluster_state() {
    local dev
    local failed=()
    local pending=()
    local all_devices=()
    local master
    master="$(state_reconcile_master | sed -n 's/^master=//p' | cut -d'|' -f1)"

    for dev in $(syncctl_list_devices); do
        all_devices+=("$dev")
        # Skip completion check for master (sendonly) — it doesn't receive data
        if [[ "$dev" == "$master" ]]; then
            continue
        fi
        if ! get_completion "$dev" >/dev/null 2>&1; then
            pending+=("$dev (offline/unreachable)")
            continue
        fi
        local body="$SYNCCTL_API_BODY"
        local pct
        pct="$(echo "$body" | syncctl_jq -r '.completion // empty' 2>/dev/null)"
        pct="${pct%%.*}"
        if [[ -z "$pct" ]]; then
            failed+=("$dev (no completion data)")
        elif (( pct < 100 )); then
            pending+=("$dev (${pct}%)")
        fi
    done

    if (( ${#pending[@]} > 0 )); then
        SYNCCTL_CHECKPOINT_REASON="out of sync: ${pending[*]}"
        return 1
    fi
    if (( ${#failed[@]} > 0 )); then
        SYNCCTL_CHECKPOINT_REASON="cluster state errors: ${failed[*]}"
        return 1
    fi
    return 0
}

check_conflicts() {
    local dev conflict_count=0
    for dev in $(syncctl_list_devices); do
        if ! get_folder_errors "$dev" >/dev/null 2>&1; then
            continue
        fi
        local body="$SYNCCTL_API_BODY"
        local cnt
        cnt="$(echo "$body" | syncctl_jq -r --arg f "$SYNCCTL_FOLDER_ID" \
            '.[$f] // [] | length' 2>/dev/null || echo 0)"
        (( conflict_count += cnt ))
    done

    if (( conflict_count > 0 )); then
        SYNCCTL_CHECKPOINT_REASON="API-reported conflicts: $conflict_count"
        return 1
    fi
    return 0
}

check_folder_types() {
    local master="$1"
    local dev type bad=()
    for dev in $(syncctl_list_devices); do
        if ! get_folder_config "$dev" >/dev/null 2>&1; then
            continue
        fi
        type="$(echo "$SYNCCTL_API_BODY" | syncctl_jq -r '.type // empty' 2>/dev/null)"
        if [[ "$dev" == "$master" ]]; then
            [[ "$type" == "sendonly" ]] || bad+=("$dev (expected sendonly, got $type)")
        else
            [[ "$type" == "receiveonly" ]] || bad+=("$dev (expected receiveonly, got $type)")
        fi
    done
    if (( ${#bad[@]} > 0 )); then
        SYNCCTL_CHECKPOINT_REASON="folder type mismatch: ${bad[*]}"
        return 1
    fi
    return 0
}

checkpoint_run() {
    local master="" init_mode=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --init) init_mode=1; shift ;;
            *) master="$1"; shift ;;
        esac
    done
    [[ -z "$master" ]] && {
        local line
        line="$(state_reconcile_master)"
        master="${line#master=}"
        master="${master%%|*}"
    }

    syncctl_init_paths
    local start_ms; start_ms="$(date +%s%3N 2>/dev/null || date +%s)000"

    local checks_passed=0 checks_total=0
    local failures=()

    for check in check_local_state check_cluster_state check_conflicts; do
        (( checks_total++ )) || true
        # During init, skip cluster state and local state
        # (devices may be offline/not yet configured, conflicts normal)
        if (( init_mode )) && [[ "$check" == "check_cluster_state" || "$check" == "check_local_state" ]]; then
            (( checks_passed++ )) || true
            continue
        fi
        if "$check"; then
            (( checks_passed++ )) || true
        else
            failures+=("$check: $SYNCCTL_CHECKPOINT_REASON")
        fi
    done

    if [[ -n "$master" ]] && (( ! init_mode )); then
        (( checks_total++ )) || true
        if check_folder_types "$master"; then
            (( checks_passed++ )) || true
        else
            failures+=("check_folder_types: $SYNCCTL_CHECKPOINT_REASON")
        fi
    fi

    local id; id="$(_next_checkpoint_id)"
    local end_ms; end_ms="$(date +%s%3N 2>/dev/null || date +%s)000"
    local duration=$(( end_ms - start_ms ))
    local result; result="fail"
    [[ ${#failures[@]} -eq 0 ]] && result="pass"

    local ckpt_file="$SYNCCTL_CHECKPOINT_DIR/${id}.json"
    cat <<EOF > "$ckpt_file"
{
  "id": "$id",
  "master": "$master",
  "folder": "$SYNCCTL_FOLDER_ID",
  "result": "$result",
  "checks_passed": $checks_passed,
  "checks_total": $checks_total,
  "duration_ms": $duration,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    SYNCCTL_CHECKPOINT_ID="$id"
    SYNCCTL_CHECKPOINT_RESULT="$result"

    audit_log "checkpoint" "id=#$id" "master=$master" "result=$result" \
        "checks=$checks_passed/$checks_total" "duration_ms=$duration"

    [[ "$result" == "pass" ]] && return 0 || return 1
}

list_checkpoints() {
    local limit="${1:-10}"
    ls -1t "$SYNCCTL_CHECKPOINT_DIR"/*.json 2>/dev/null | head -n "$limit" | while read -r f; do
        syncctl_jq -r '"\(.id) \(.result) \(.timestamp) master=\(.master)"' "$f" 2>/dev/null
    done
}
