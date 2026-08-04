#!/bin/bash
# ============================================================
# syncctl/lib/state.sh — Master cache + handover state
# ============================================================
# Two storage layers:
#   1. Local cache  → ~/.local/share/syncctl/master
#   2. Local state  → ~/.local/share/syncctl/state.json
#   3. Synced SSOT  → $SSOT/.syncctl/master (read-only here)
#
# Design decision 23.1 (Hybrid storage with reconcile)
# ============================================================

# Guard
[[ -n "${_SYNCCTL_STATE_LOADED:-}" ]] && return 0
_SYNCCTL_STATE_LOADED=1

# Source config (paths)
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# ──────────────────────────────────────────────────────────
# Local master cache: ~/.local/share/syncctl/master
# Plain text. One line. Just the device name.
# ──────────────────────────────────────────────────────────

state_get_local_master() {
    [[ -f "$SYNCCTL_LOCAL_MASTER_FILE" ]] || return 0
    head -1 "$SYNCCTL_LOCAL_MASTER_FILE" 2>/dev/null
}

state_set_local_master() {
    local dev="$1"
    syncctl_init_paths
    printf '%s\n' "$dev" > "$SYNCCTL_LOCAL_MASTER_FILE"
}

# ──────────────────────────────────────────────────────────
# Synced SSOT: $SSOT/.syncctl/master
# ──────────────────────────────────────────────────────────

state_get_synced_master() {
    [[ -f "$SYNCCTL_SYNCED_MASTER_FILE" ]] || return 0
    head -1 "$SYNCCTL_SYNCED_MASTER_FILE" 2>/dev/null
}

state_set_synced_master() {
    local dev="$1"
    mkdir -p "$SYNCCTL_SYNCED_MASTER_DIR"
    printf '%s\n' "$dev" > "$SYNCCTL_SYNCED_MASTER_FILE"
    [[ -f "$SYNCCTL_SYNCED_MASTER_DIR/.keep" ]] || \
        printf '# syncctl master pointer (auto-generated, do not edit)\n' \
        > "$SYNCCTL_SYNCED_MASTER_DIR/.keep"
}

# ──────────────────────────────────────────────────────────
# Reconcile: pick authoritative master value
# Outputs: "master=<dev>|source=<local|synced|default>"
# Returns: 0 always
# ──────────────────────────────────────────────────────────
state_reconcile_master() {
    local local_m synced_m

    local_m="$(state_get_local_master)"
    synced_m="$(state_get_synced_master)"

    # Both missing → uninitialized
    if [[ -z "$local_m" && -z "$synced_m" ]]; then
        printf 'master=|source=uninitialized\n'
        return 0
    fi

    # Only synced → use synced (new device joining)
    if [[ -z "$local_m" && -n "$synced_m" ]]; then
        state_set_local_master "$synced_m"
        printf 'master=%s|source=synced\n' "$synced_m"
        return 0
    fi

    # Only local → use local (initial state, hasn't synced yet)
    if [[ -n "$local_m" && -z "$synced_m" ]]; then
        printf 'master=%s|source=local\n' "$local_m"
        return 0
    fi

    # Both exist, agree → use it
    if [[ "$local_m" == "$synced_m" ]]; then
        printf 'master=%s|source=both\n' "$local_m"
        return 0
    fi

    # Disagree → Fail closed. DO NOT auto-reconcile or overwrite local state.
    printf 'master=|source=conflict|local_was=%s|synced_was=%s\n' "$local_m" "$synced_m"
    return 0
}

# ──────────────────────────────────────────────────────────
# state.json — durable handover state (atomic read/write)
# ──────────────────────────────────────────────────────────
state_json_get() {
    local key="$1"
    [[ -f "$SYNCCTL_STATE" ]] || { printf ''; return 0; }
    syncctl_jq -r --arg k "$key" '.[$k] // empty' "$SYNCCTL_STATE" 2>/dev/null
}

state_json_set() {
    local key="$1" value="$2"
    syncctl_init_paths
    local tmp; tmp="$(mktemp)"
    if [[ -f "$SYNCCTL_STATE" ]]; then
        syncctl_jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$SYNCCTL_STATE" > "$tmp" 2>/dev/null || {
            rm -f "$tmp"
            syncctl_jq -n --arg k "$key" --arg v "$value" '{($k):$v}' > "$tmp" 2>/dev/null || {
                cat <<EOF > "$tmp"
{
  "$key": "$value"
}
EOF
            }
        }
    else
        syncctl_jq -n --arg k "$key" --arg v "$value" '{($k):$v}' > "$tmp" 2>/dev/null || {
            cat <<EOF > "$tmp"
{
  "$key": "$value"
}
EOF
        }
    fi
    mv "$tmp" "$SYNCCTL_STATE"
}

state_json_init_if_missing() {
    syncctl_init_paths
    if [[ ! -f "$SYNCCTL_STATE" ]] || ! syncctl_jq -e . "$SYNCCTL_STATE" >/dev/null 2>&1; then
        cat <<EOF > "$SYNCCTL_STATE"
{
  "handover_in_progress": false,
  "from": null,
  "to": null,
  "step": 0,
  "phase": "IDLE",
  "started_at": null,
  "checkpoint_id": null
}
EOF
    fi
}

state_handover_begin() {
    local from="$1" to="$2" step="$3" chk_id="$4" phase="${5:-PRECHECK}"
    state_json_init_if_missing
    state_json_set handover_in_progress true
    state_json_set from "$from"
    state_json_set to "$to"
    state_json_set step "$step"
    state_json_set phase "$phase"
    state_json_set started_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    state_json_set checkpoint_id "$chk_id"
}

state_handover_step() {
    state_json_set step "$1"
    [[ $# -ge 2 ]] && state_json_set phase "$2"
}

state_handover_phase() {
    state_json_set phase "$1"
}

state_handover_complete() {
    state_json_init_if_missing
    state_json_set handover_in_progress false
    state_json_set from null
    state_json_set to null
    state_json_set step 0
    state_json_set phase "IDLE"
    state_json_set started_at null
    state_json_set checkpoint_id null
}

state_handover_is_stale() {
    local started_at
    started_at="$(state_json_get started_at)"
    [[ -z "$started_at" ]] && return 1
    local now started_epoch
    now="$(date +%s)"
    if command -v gdate >/dev/null 2>&1; then
        started_epoch="$(gdate -d "$started_at" +%s 2>/dev/null)" || return 1
    else
        started_epoch="$(date -d "$started_at" +%s 2>/dev/null)" || return 1
    fi
    (( now - started_epoch > SYNCCTL_HANDOVER_STALE_TIMEOUT ))
}

audit_log() {
    local event="$1"
    shift
    syncctl_init_paths
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local extra="$*"
    if [[ "${1:-}" =~ ^\{ ]]; then
        local obj="$1"
        shift
        printf '{"ts":"%s","event":"%s",%s}\n' "$ts" "$event" "${obj#\{}" \
            >> "$SYNCCTL_AUDIT_LOG"
    else
        printf '{"ts":"%s","event":"%s","detail":"%s"}\n' "$ts" "$event" "$*" \
            >> "$SYNCCTL_AUDIT_LOG"
    fi
}
