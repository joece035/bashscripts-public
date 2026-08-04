#!/bin/bash
# ============================================================
# syncctl/lib/handover.sh — Master handover (transfer/init)
# ============================================================
# Safe Master Handover Protocol:
#   1. Acquire lock
#   2. Check stale state (recovery menu if stale)
#   3. Run pre-checkpoint (GATE: abort if fail)
#   4. Set state.json = HANDOVER_IN_PROGRESS
#   5. Re-verify target reachability / completion
#   6. DEMOTE OLD MASTER FIRST (master count = 0)
#   7. Verify old master is RECEIVE ONLY
#   8. PROMOTE TARGET SECOND (master count = 1)
#   9. Verify target is SEND ONLY
#  10. Update master pointers (COMMIT POINT)
#  11. Run post-checkpoint (GATE: return non-zero if fail)
#  12. Clear state.json & Release lock
# ============================================================

# Guard
[[ -n "${_SYNCCTL_HANDOVER_LOADED:-}" ]] && return 0
_SYNCCTL_HANDOVER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/api.sh"
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lock.sh"
source "$(dirname "${BASH_SOURCE[0]}")/checkpoint.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ownership.sh"

# ──────────────────────────────────────────────────────────
# init_master <device>
# First-time setup: assume no master exists yet
# ──────────────────────────────────────────────────────────
init_master() {
    local target="$1"
    local reason="${2:-first-time-setup}"

    if ! syncctl_is_known_device "$target"; then
        echo "init: unknown device '$target'" >&2
        return 1
    fi

    # Check if already initialized
    local existing
    existing="$(state_reconcile_master | sed -n 's/^master=//p' | cut -d'|' -f1)"
    if [[ -n "$existing" ]]; then
        echo "init: already initialized, master=$existing" >&2
        echo "  use 'syncctl transfer $target' instead" >&2
        return 1
    fi

    lock_acquire || return 1
    trap 'lock_release' RETURN

    echo "Initializing master = $target"

    # 1. Pre-checkpoint (--init skips folder-type check: types not set yet)
    if ! checkpoint_run --init "$target"; then
        echo "⛔ INIT FAILED — pre-checkpoint did not pass" >&2
        echo "  Reason: $SYNCCTL_CHECKPOINT_REASON" >&2
        return 1
    fi
    local chk_id="$SYNCCTL_CHECKPOINT_ID"

    # 2. Set state
    state_handover_begin "" "$target" 1 "$chk_id" "INIT_BEGIN"

    # 3. Apply ownership: target=sendonly, others=receiveonly
    if ! apply_ownership "$target" 1; then
        echo "⛔ INIT FAILED — could not apply ownership" >&2
        state_handover_complete
        return 1
    fi

    # 4. Write master pointers
    state_set_local_master "$target"
    state_set_synced_master "$target"

    # 5. Post-checkpoint (--init: skip cluster/local checks for first-time setup)
    if ! checkpoint_run --init "$target"; then
        echo "⚠️  INIT INCOMPLETE — post-checkpoint failed" >&2
        echo "  Reason: $SYNCCTL_CHECKPOINT_REASON" >&2
        state_handover_complete
        return 1
    fi

    # 6. Clear state
    state_handover_complete

    audit_log "init" "master=$target" "reason=$reason" "checkpoint=#$chk_id"
    echo "✅ Master initialized: $target (checkpoint #$chk_id)"
    return 0
}

# ──────────────────────────────────────────────────────────
# transfer_master <target_device> [--force] [--reason "..."] [--dry-run]
# ──────────────────────────────────────────────────────────
transfer_master() {
    local target="" force=0 dry_run=0 reason=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force) force=1; shift ;;
            --dry-run) dry_run=1; shift ;;
            --reason) reason="$2"; shift 2 ;;
            *) target="$1"; shift ;;
        esac
    done

    if [[ -z "$target" ]]; then
        echo "transfer: missing target device" >&2
        return 1
    fi
    if ! syncctl_is_known_device "$target"; then
        echo "transfer: unknown device '$target'" >&2
        return 1
    fi

    # Idempotency: already master?
    local reconcile_res current source
    reconcile_res="$(state_reconcile_master)"
    current="$(echo "$reconcile_res" | sed -n 's/^master=//p' | cut -d'|' -f1)"
    source="$(echo "$reconcile_res" | sed -n 's/.*source=//p' | cut -d'|' -f1)"

    if [[ "$source" == "conflict" ]]; then
        echo "⛔ OWNERSHIP STATE CONFLICT" >&2
        echo "Local master and synced master disagree." >&2
        echo "The authoritative master cannot be determined automatically." >&2
        echo "NO CHANGES HAVE BEEN MADE." >&2
        return 1
    fi

    if [[ "$current" == "$target" ]]; then
        echo "✓ $target is already MASTER" >&2
        echo "No action required."
        return 0
    fi

    # ─── Recovery check: stale handover? ───
    if state_json_get handover_in_progress 2>/dev/null | grep -qi true; then
        if state_handover_is_stale; then
            echo "⛔ STALE HANDOVER DETECTED" >&2
            echo "  Started: $(state_json_get started_at)" >&2
            echo "  From: $(state_json_get from) → To: $(state_json_get to)" >&2
            echo "  Last step: $(state_json_get step) [$(state_json_get phase)]" >&2
            echo "" >&2
            echo "Run 'syncctl recover' to resolve." >&2
            return 1
        fi
    fi

    # ─── Force mode handling (Break-Glass) ───
    if [[ "$force" == "1" ]]; then
        if [[ -z "$reason" ]]; then
            echo "⛔ --force requires --reason" >&2
            return 1
        fi
        echo "⚠️  BREAK-GLASS MODE (--force)" >&2
        echo "  Normal checkpoint and reachability checks overridden." >&2
        echo "  Reason: $reason" >&2
        audit_log "break_glass_transfer" "from=${current:-NONE}" "to=$target" "reason=$reason"
    fi

    # ─── Dry run ───
    if [[ "$dry_run" == "1" ]]; then
        echo "DRY RUN"
        echo "  Current Master: ${current:-NONE}"
        echo "  Target Master:  $target"
        echo ""
        if checkpoint_run "$current" 2>/dev/null; then
            echo "  Checkpoint:     PASS (#$SYNCCTL_CHECKPOINT_ID)"
        else
            echo "  Checkpoint:     FAIL ($SYNCCTL_CHECKPOINT_REASON)"
        fi
        echo ""
        echo "Planned changes (Strict Order: Demote Old First, Promote Target Second):"
        for dev in $(syncctl_list_devices); do
            if [[ "$dev" == "$current" && "$dev" != "$target" ]]; then
                echo "  1. $dev  SEND ONLY → RECEIVE ONLY (Demote first)"
            elif [[ "$dev" == "$target" ]]; then
                echo "  2. $dev  RECEIVE ONLY → SEND ONLY (Promote second)"
            else
                echo "  - $dev  RECEIVE ONLY (unchanged)"
            fi
        done
        echo ""
        echo "No changes applied."
        return 0
    fi

    # ─── Real transfer ───
    lock_acquire || return 1
    trap 'lock_release' RETURN

    # 1. Pre-checkpoint
    state_handover_begin "$current" "$target" 1 "" "CHECKPOINTING"
    if [[ "$force" != "1" ]]; then
        if ! checkpoint_run "$current"; then
            echo "⛔ TRANSFER ABORTED — pre-checkpoint did not pass" >&2
            echo "  Reason: $SYNCCTL_CHECKPOINT_REASON" >&2
            echo "  Master remains: ${current:-uninitialized}" >&2
            state_handover_complete
            audit_log "transfer" "from=$current" "to=$target" "result=aborted" "reason=$SYNCCTL_CHECKPOINT_REASON"
            return 1
        fi
    fi
    local pre_chk="${SYNCCTL_CHECKPOINT_ID:-none}"
    state_handover_step 1 "PRECHECK_PASSED"

    # 2. Re-verify target reachability (TOCTOU guard)
    if [[ "$force" != "1" ]]; then
        if ! get_completion "$target" >/dev/null 2>&1; then
            echo "⛔ TRANSFER ABORTED — target '$target' unreachable" >&2
            state_handover_complete
            return 1
        fi
    fi
    state_handover_step 2 "TARGET_VERIFIED"

    # 3. DEMOTE OLD MASTER FIRST (Safe handover order: Master count <= 1)
    state_handover_step 3 "DEMOTING_OLD"
    if [[ -n "$current" ]]; then
        if ! demote_from_master "$current"; then
            echo "⛔ TRANSFER ABORTED — failed to demote old master '$current'" >&2
            state_handover_step 3 "FAILED_DEMOTE_OLD"
            state_handover_phase "RECOVERY_REQUIRED"
            return 1
        fi
        local old_type; old_type="$(get_folder_type "$current")"
        if [[ "$old_type" != "receiveonly" && "$old_type" != "unknown" ]]; then
            echo "⛔ TRANSFER ABORTED — demoted old master '$current' is not receiveonly ($old_type)" >&2
            state_handover_step 3 "FAILED_DEMOTE_OLD_VERIFY"
            state_handover_phase "RECOVERY_REQUIRED"
            return 1
        fi
    fi
    state_handover_step 4 "DEMOTED_OLD"

    # Demote all non-target devices
    for dev in $(syncctl_list_devices); do
        [[ "$dev" == "$target" || "$dev" == "$current" ]] && continue
        demote_from_master "$dev" 2>/dev/null || true
    done

    # 4. PROMOTE TARGET SECOND
    state_handover_step 5 "PROMOTING_TARGET"
    if ! promote_to_master "$target"; then
        echo "⛔ TRANSFER ABORTED — could not promote target '$target'" >&2
        # Real Rollback Attempt
        if [[ -n "$current" ]]; then
            echo "Attempting rollback: restoring old master '$current'..." >&2
            promote_to_master "$current" || echo "⚠️ Rollback failed to restore '$current'" >&2
        fi
        state_handover_step 5 "FAILED_PROMOTE_TARGET"
        state_handover_phase "RECOVERY_REQUIRED"
        return 1
    fi

    # Verify target is sendonly
    local target_type; target_type="$(get_folder_type "$target")"
    if [[ "$target_type" != "sendonly" ]]; then
        echo "⛔ TRANSFER ABORTED — promoted target '$target' is not sendonly ($target_type)" >&2
        if [[ -n "$current" ]]; then
            echo "Attempting rollback: restoring old master '$current'..." >&2
            demote_from_master "$target" 2>/dev/null || true
            promote_to_master "$current" || echo "⚠️ Rollback failed to restore '$current'" >&2
        fi
        state_handover_step 5 "FAILED_PROMOTE_TARGET_VERIFY"
        state_handover_phase "RECOVERY_REQUIRED"
        return 1
    fi
    state_handover_step 6 "PROMOTED_TARGET"

    # 5. COMMIT NEW MASTER (Pointer updates)
    state_set_local_master "$target"
    state_set_synced_master "$target"
    state_handover_step 7 "COMMITTED"

    # 6. Post-checkpoint
    if [[ "$force" != "1" ]]; then
        if ! checkpoint_run "$target"; then
            echo "⚠️  TRANSFER INCOMPLETE (DEGRADED)" >&2
            echo "  Master applied: $target" >&2
            echo "  Post-checkpoint failed: $SYNCCTL_CHECKPOINT_REASON" >&2
            state_handover_complete
            audit_log "transfer" "from=$current" "to=$target" "result=degraded" \
                "checkpoint=#$pre_chk" "reason=$reason" "force=$force"
            return 1
        fi
    fi

    state_handover_complete
    audit_log "transfer" "from=$current" "to=$target" "result=ok" \
        "checkpoint=#$pre_chk" "reason=$reason" "force=$force"
    echo "✅ Transfer complete: ${current:-NONE} → $target"
    return 0
}

# ──────────────────────────────────────────────────────────
# recover_stale_handover
# Called when state.json shows stale handover
# ──────────────────────────────────────────────────────────
recover_stale_handover() {
    state_json_init_if_missing
    local in_progress from to step phase started_at
    in_progress="$(state_json_get handover_in_progress)"
    [[ "$in_progress" == "true" ]] || { echo "No stale handover."; return 0; }

    from="$(state_json_get from)"
    to="$(state_json_get to)"
    step="$(state_json_get step)"
    phase="$(state_json_get phase)"
    started_at="$(state_json_get started_at)"

    echo "⚠️  STALE / INTERRUPTED HANDOVER DETECTED"
    echo "  Started: $started_at"
    echo "  From: ${from:-NONE} → To: $to"
    echo "  Last step: $step [$phase]"
    echo ""

    # Inspect current actual Syncthing state
    echo "Current Syncthing folder types:"
    for dev in $(syncctl_list_devices); do
        echo "  $dev: $(get_folder_type "$dev")"
    done
    echo ""

    echo "  1) ABORT    — rollback to old master ($from), mark idle"
    echo "  2) CONTINUE — complete transfer to target ($to)"
    echo "  3) RESET    — force mark idle without changing folder types"
    echo ""
    read -r -p "Choice [1/2/3]: " ch
    case "$ch" in
        1) if [[ -n "$from" ]]; then
               promote_to_master "$from" 2>/dev/null || true
               demote_from_master "$to" 2>/dev/null || true
               state_set_local_master "$from"
               state_set_synced_master "$from"
           fi
           state_handover_complete
           audit_log "recover" "action=abort" "from=$from" "to=$to"
           echo "✅ Handover aborted and rolled back. Master: ${from:-NONE}"
           ;;
        2) transfer_master "$to" --reason "recovery from stale phase $phase" ;;
        3) state_handover_complete
           audit_log "recover" "action=reset" "from=$from" "to=$to"
           echo "✅ Handover state reset."
           ;;
        *) echo "Invalid choice."; return 1 ;;
    esac
}
