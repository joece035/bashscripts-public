#!/bin/bash
# ============================================================
# syncctl/lib/ownership.sh — Set folder type on each device
# ============================================================
# Wraps set_folder_type from api.sh with logging + safety.
# Each function is small + idempotent.
# ============================================================

# Guard
[[ -n "${_SYNCCTL_OWNERSHIP_LOADED:-}" ]] && return 0
_SYNCCTL_OWNERSHIP_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/api.sh"
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"

promote_to_master() {
    local dev="$1"
    if ! syncctl_is_known_device "$dev"; then
        echo "ownership: unknown device '$dev'" >&2
        return 1
    fi
    if ! set_folder_type "$dev" "sendonly"; then
        echo "ownership: failed to set $dev=sendonly: $SYNCCTL_API_ERR" >&2
        return 1
    fi
    audit_log "ownership" "action=promote" "device=$dev" "type=sendonly"
    return 0
}

demote_from_master() {
    local dev="$1"
    if ! syncctl_is_known_device "$dev"; then
        echo "ownership: unknown device '$dev'" >&2
        return 1
    fi
    if ! set_folder_type "$dev" "receiveonly"; then
        echo "ownership: failed to set $dev=receiveonly: $SYNCCTL_API_ERR" >&2
        return 1
    fi
    audit_log "ownership" "action=demote" "device=$dev" "type=receiveonly"
    return 0
}

apply_ownership() {
    local master="$1" init_mode="${2:-0}"
    local dev
    local ok=1

    for dev in $(syncctl_list_devices); do
        if [[ "$dev" == "$master" ]]; then
            promote_to_master "$dev" || ok=0
        else
            demote_from_master "$dev" || ok=0
        fi
    done

    # During init: warn on failures (offline devices will sync later)
    if (( ok == 0 && init_mode )); then
        echo "ownership: some devices unreachable — will apply when they come online" >&2
        return 0
    fi
    return $(( 1 - ok ))
}

get_folder_type() {
    local dev="$1"
    if ! get_folder_config "$dev" >/dev/null 2>&1; then
        echo "unknown"
        return 1
    fi
    echo "$SYNCCTL_API_BODY" | syncctl_jq -r '.type // "unknown"' 2>/dev/null || echo "unknown"
}

ownership_table() {
    local dev master
    master="$(state_reconcile_master | sed -n 's/^master=//p' | cut -d'|' -f1)"

    printf '%-10s %-14s %s\n' "DEVICE" "TYPE" "ROLE"
    printf '%-10s %-14s %s\n' "----------" "--------------" "----"
    for dev in $(syncctl_list_devices); do
        local type role
        type="$(get_folder_type "$dev")"
        if [[ -n "$master" && "$dev" == "$master" ]]; then
            role="MASTER"
        else
            role="REPLICA"
        fi
        printf '%-10s %-14s %s\n' "$dev" "$type" "$role"
    done
}
