#!/bin/bash
# ============================================================
# syncctl/lib/doctor.sh — Full audit
# ============================================================
# Checks:
#   1. CRLF in any .sh file (cross-env safety)
#   2. Master state consistency (local vs synced)
#   3. .sync-conflict-* files
#   4. Folder type invariant
#   5. Lock stale?
#   6. API reachability for all known devices
#   7. Stale handover state
# ============================================================

# Guard
[[ -n "${_SYNCCTL_DOCTOR_LOADED:-}" ]] && return 0
_SYNCCTL_DOCTOR_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/api.sh"
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lock.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ownership.sh"

# Color helper functions
_R_OK()    { cn 46  b "$@"; }
_R_WARN()  { cn 226 "" "$@"; }
_R_ERR()   { cn 196 b "$@"; }
_R_INFO()  { cn 75  b "$@"; }
_R_BOLD()  { cn w   b "$@"; }
_R_DIM()   { cn 244 d "$@"; }

doctor_run() {
    local errors=0 warns=0
    printf "\n%s\n\n" "$(c w b '═══ syncctl doctor ═══')"

    # 1. CRLF
    printf "  %s CRLF check ... " "$(_R_INFO '[1/7]')"
    local crlf
    crlf="$(grep -rlU $'\r' "$SYNCCTL_FOLDER_ROOT" --include="*.sh" 2>/dev/null)"
    if [[ -z "$crlf" ]]; then
        printf "%s\n" "$(_R_OK PASS)"
    else
        printf "%s  %s\n" "$(_R_ERR FAIL)" "$(_R_WARN '(auto-fix recommended)')"
        (( warns++ )) || true
    fi

    # 2. Master state
    printf "  %s Master state consistency ... " "$(_R_INFO '[2/7]')"
    local local_m synced_m
    local_m="$(state_get_local_master)"
    synced_m="$(state_get_synced_master)"
    if [[ -z "$local_m" && -z "$synced_m" ]]; then
        printf "%s  uninitialized\n" "$(_R_WARN WARN)"
        (( warns++ )) || true
    elif [[ -n "$local_m" && -n "$synced_m" && "$local_m" != "$synced_m" ]]; then
        printf "%s  local=$local_m synced=$synced_m\n" "$(_R_ERR FAIL)"
        (( errors++ )) || true
    else
        printf "%s  master=$local_m\n" "$(_R_OK PASS)"
    fi

    # 3. Conflicts
    printf "  %s Conflict files ... " "$(_R_INFO '[3/7]')"
    local cf
    cf="$(find "$SYNCCTL_FOLDER_ROOT" -name '*.sync-conflict-*' -type f 2>/dev/null | wc -l)"
    if (( cf == 0 )); then
        printf "%s\n" "$(_R_OK PASS)"
    else
        printf "%s  %s\n" "$(_R_ERR FAIL)" "$(_R_WARN "($cf files)")"
        (( errors++ )) || true
    fi

    # 4. Folder types
    printf "  %s Folder type invariant ... " "$(_R_INFO '[4/7]')"
    local master="${local_m:-${synced_m:-}}"
    local bad=0
    if [[ -n "$master" ]]; then
        local dev t
        for dev in $(syncctl_list_devices); do
            t="$(get_folder_type "$dev")"
            if [[ "$dev" == "$master" && "$t" != "sendonly" ]]; then
                (( bad++ )) || true
            elif [[ "$dev" != "$master" && "$t" != "receiveonly" && "$t" != "unknown" ]]; then
                (( bad++ )) || true
            fi
        done
    fi
    if (( bad == 0 )); then
        printf "%s\n" "$(_R_OK PASS)"
    else
        printf "%s  %s\n" "$(_R_ERR FAIL)" "$(_R_WARN "($bad device(s) wrong type)")"
        (( errors++ )) || true
    fi

    # 5. Lock
    printf "  %s Lock state ... " "$(_R_INFO '[5/7]')"
    if lock_is_held; then
        printf "%s  held by pid %s\n" "$(_R_WARN WARN)" "$(lock_holder_pid)"
        (( warns++ )) || true
    else
        printf "%s\n" "$(_R_OK PASS)"
    fi

    # 6. API reachability
    printf "  %s API reachability ...\n" "$(_R_INFO '[6/7]')"
    local dev
    for dev in $(syncctl_list_devices); do
        printf "    %-10s " "$dev"
        if get_system_version "$dev" >/dev/null 2>&1; then
            local ver
            ver="$(echo "$SYNCCTL_API_BODY" | jq -r '.version // "?"' 2>/dev/null || echo "?")"
            printf "%s  v%s\n" "$(_R_OK PASS)" "$ver"
        else
            printf "%s\n" "$(_R_WARN "(offline/unreachable)")"
            (( warns++ )) || true
        fi
    done

    # 7. Stale handover
    printf "  %s Handover state ... " "$(_R_INFO '[7/7]')"
    state_json_init_if_missing
    if [[ "$(state_json_get handover_in_progress)" == "true" ]]; then
        if state_handover_is_stale; then
            printf "%s  %s\n" "$(_R_ERR STALE)" "$(_R_WARN "(run 'syncctl recover')")"
            (( errors++ )) || true
        else
            printf "%s  in progress\n" "$(_R_WARN WARN)"
            (( warns++ )) || true
        fi
    else
        printf "%s\n" "$(_R_OK PASS)"
    fi

    printf "\n%s " "$(_R_BOLD 'Summary:')"
    if (( errors == 0 && warns == 0 )); then
        printf "%s\n\n" "$(_R_OK 'ALL CHECKS PASSED')"
        return 0
    fi
    printf "%s error(s), %s warning(s)\n\n" "$(_R_ERR "$errors")" "$(_R_WARN "$warns")"
    return $(( errors > 0 ? 1 : 0 ))
}
