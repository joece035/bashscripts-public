#!/bin/bash
# ============================================================
# syncctl/lib/ownership.sh — Folder type + ownership operations
# ============================================================
# Wraps set_folder_type from api.sh with logging + safety.
# Each function is small + idempotent.
#
# Two flavors:
#   - Single-device ops: promote_to_master / demote_from_master / set_type_device
#   - Cluster ops:       apply_ownership / fix_types
# ============================================================

# Guard
[[ -n "${_SYNCCTL_OWNERSHIP_LOADED:-}" ]] && return 0
_SYNCCTL_OWNERSHIP_LOADED=1

source "${SYNCCTL_LIB_DIR:-$(dirname "$0")}/config.sh"
source "${SYNCCTL_LIB_DIR:-$(dirname "$0")}/api.sh"
source "${SYNCCTL_LIB_DIR:-$(dirname "$0")}/state.sh"
source "${SYNCCTL_LIB_DIR:-$(dirname "$0")}/lock.sh"

# ──────────────────────────────────────────────────────────
# Single-device: set master
# ──────────────────────────────────────────────────────────
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

# ──────────────────────────────────────────────────────────
# Single-device: demote
# ──────────────────────────────────────────────────────────
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

# ──────────────────────────────────────────────────────────
# Single-device: set arbitrary type (escape hatch)
# Validates: sendonly|receiveonly|sendreceive
# Idempotent: noop if already at target type
# ──────────────────────────────────────────────────────────
set_type_device() {
    local dev="$1" new_type="$2"
    if ! syncctl_is_known_device "$dev"; then
        echo "ownership: unknown device '$dev'" >&2
        SYNCCTL_API_ERR="unknown device"
        return 1
    fi
    case "$new_type" in
        sendonly|receiveonly|sendreceive) ;;
        *)
            echo "ownership: invalid type '$new_type' (must be sendonly|receiveonly|sendreceive)" >&2
            SYNCCTL_API_ERR="invalid folder type: $new_type"
            return 1
            ;;
    esac

    # Idempotency: skip if already at target
    local current
    current="$(get_folder_type "$dev" 2>/dev/null || echo "unknown")"
    if [[ "$current" == "$new_type" ]]; then
        audit_log "ownership" "action=set_type_noop" "device=$dev" "type=$new_type"
        return 0
    fi

    if ! set_folder_type "$dev" "$new_type"; then
        echo "ownership: failed to set $dev=$new_type: $SYNCCTL_API_ERR" >&2
        return 1
    fi
    audit_log "ownership" "action=set_type" "device=$dev" "type=$new_type" "was=$current"
    return 0
}

# ──────────────────────────────────────────────────────────
# Cluster: apply ownership (used by init/transfer)
# ──────────────────────────────────────────────────────────
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

# ──────────────────────────────────────────────────────────
# Cluster: fix-types (NEW)
# Reconcile folder types with current master without changing master pointer.
# - master device → sendonly
# - all other devices → receiveonly
# - dry-run supported
# - locked to prevent race with transfer
# - does NOT touch state.json (this is not a handover)
# ──────────────────────────────────────────────────────────
fix_types() {
    local dry_run=0 reason=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) dry_run=1; shift ;;
            --reason)  reason="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Need a master to fix against
    local master
    master="$(state_reconcile_master | sed -n 's/^master=//p' | cut -d'|' -f1)"
    if [[ -z "$master" ]]; then
        echo "fix-types: no master — run 'syncctl init <device>' first" >&2
        return 1
    fi

    # State conflict → refuse (must reconcile master first)
    local src
    src="$(state_reconcile_master | sed -n 's/^source=//p' | cut -d'|' -f1)"
    if [[ "$src" == "conflict" ]]; then
        echo "fix-types: master state is in CONFLICT — run 'syncctl recover' first" >&2
        return 1
    fi

    # Acquire lock (same as transfer)
    lock_acquire || { echo "fix-types: another syncctl operation in progress" >&2; return 1; }
    trap 'lock_release' RETURN

    if (( dry_run )); then
        echo "═══ DRY RUN: fix-types (no changes will be made) ═══"
        echo "  Master : $master → sendonly"
        echo "  Replicas:"
    fi

    local dev current expected ok=1 changed=0
    for dev in $(syncctl_list_devices); do
        if [[ "$dev" == "$master" ]]; then
            expected="sendonly"
        else
            expected="receiveonly"
        fi

        current="$(get_folder_type "$dev" 2>/dev/null || echo "unknown")"

        if [[ "$current" == "$expected" ]]; then
            if (( dry_run )); then
                echo "    $dev  $current  (already correct)"
            fi
            continue
        fi

        if (( dry_run )); then
            echo "    $dev  $current  →  $expected  (would change)"
            continue
        fi

        # Real change
        if [[ "$dev" == "$master" ]]; then
            promote_to_master "$dev" || { ok=0; continue; }
        else
            demote_from_master "$dev" || { ok=0; continue; }
        fi
        (( changed++ )) || true
    done

    if (( dry_run )); then
        echo ""
        echo "No changes applied (dry-run)."
    else
        if (( changed == 0 )); then
            echo "fix-types: all devices already correct (master=$master)"
        else
            echo "fix-types: fixed $changed device(s) (master=$master)"
        fi
        audit_log "fix-types" "master=$master" "changed=$changed" "reason=${reason:-manual}"
    fi

    return $(( 1 - ok ))
}

# ──────────────────────────────────────────────────────────
# Read: get current type for a device
# ──────────────────────────────────────────────────────────
get_folder_type() {
    local dev="$1"
    if ! get_folder_config "$dev" >/dev/null 2>&1; then
        echo "unknown"
        return 1
    fi
    echo "$SYNCCTL_API_BODY" | syncctl_jq -r '.type // "unknown"' 2>/dev/null || echo "unknown"
}

# ──────────────────────────────────────────────────────────
# Render: ownership table (DEVICE | TYPE | EXPECTED | STATUS)
# Used by `syncctl types` and `syncctl fix-types --dry-run`
# ──────────────────────────────────────────────────────────
ownership_table() {
    local dev master
    master="$(state_reconcile_master | sed -n 's/^master=//p' | cut -d'|' -f1)"

    printf '%-10s %-14s %-14s %s\n' "DEVICE" "CURRENT" "EXPECTED" "STATUS"
    printf '%-10s %-14s %-14s %s\n' "----------" "--------------" "--------------" "------"
    for dev in $(syncctl_list_devices); do
        local type expected dev_status role
        type="$(get_folder_type "$dev")"
        if [[ -n "$master" && "$dev" == "$master" ]]; then
            expected="sendonly"
            role="MASTER"
        else
            expected="receiveonly"
            role="REPLICA"
        fi
        if [[ "$type" == "$expected" ]]; then
            dev_status="✓ ok"
        else
            dev_status="✗ MISMATCH"
        fi
        printf '%-10s %-14s %-14s %s\n' "$dev" "$type" "$expected" "$dev_status ($role)"
    done
}
