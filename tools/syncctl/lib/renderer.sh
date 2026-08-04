#!/bin/bash
# ============================================================
# syncctl/lib/renderer.sh — Pretty output
# ============================================================
# V4 SSOT style — uses c()/cn() helpers from 01-colors.sh ONLY.
# NO local color vars. NO inline ANSI escapes.
# Pure functions: take data, output to stdout.
# ============================================================

# Guard
[[ -n "${_SYNCCTL_RENDERER_LOADED:-}" ]] && return 0
_SYNCCTL_RENDERER_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/state.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ownership.sh"

# Box drawing
_r_top()    { printf '╭────────────────────────────────────────────╮\n'; }
_r_sep()    { printf '├────────────────────────────────────────────┤\n'; }
_r_bot()    { printf '╰────────────────────────────────────────────╯\n'; }
_r_line()   { printf '│ %-42s │\n' "$1"; }

_r_line_c() {
    local color="$1" style="${2:-}" text="$3"
    printf '│ %s │\n' "$(cn "$color" "$style" "$text")"
}

render_status() {
    local line master source local_was synced_was
    line="$(state_reconcile_master)"
    master="${line#master=}"
    master="${master%%|*}"
    source="${line#*source=}"
    source="${source%%|*}"
    local_was="${line#*local_was=}"
    local_was="${local_was%%|*}"
    synced_was="${line#*synced_was=}"
    synced_was="${synced_was%%|*}"

    local last_ckpt
    last_ckpt="$(ls -1t "$SYNCCTL_CHECKPOINT_DIR"/*.json 2>/dev/null | head -1)"

    _r_top
    _r_line_c w b "SYNC CONTROL"
    _r_sep

    if [[ "$source" == "conflict" ]]; then
        _r_line_c 196 b "⛔ MASTER CONFLICT DETECTED"
        _r_line_c 196 "" "  Local authority : $local_was"
        _r_line_c 196 "" "  Synced authority: $synced_was"
        _r_line_c 226 "" "  Action: Operator recovery required"
    elif [[ -z "$master" ]]; then
        _r_line_c 226 "" "MASTER : (uninitialized — run syncctl init)"
    else
        _r_line_c 46 b "MASTER : $master"
    fi

    _r_sep
    _r_line_c w b "DEVICES"
    _r_sep
    local dev type role
    for dev in $(syncctl_list_devices); do
        type="$(get_folder_type "$dev")"
        if [[ -n "$master" && "$dev" == "$master" ]]; then
            role="✓ MASTER"
            _r_line_c 46 b "  $dev  ${type}  ✓ MASTER"
        else
            local in_sync="?"
            if get_completion "$dev" >/dev/null 2>&1; then
                local pct
                pct="$(echo "$SYNCCTL_API_BODY" | syncctl_jq -r '.completion // 0' 2>/dev/null || echo 0)"
                if [[ "$pct" == "100" ]]; then
                    in_sync="✓ SYNCED"
                    _r_line_c 46 b "  $dev  ${type}  ✓ SYNCED"
                else
                    in_sync="${pct}%"
                    _r_line_c 226 "" "  $dev  ${type}  ${pct}%"
                fi
            else
                _r_line_c 226 "" "  $dev  ${type}  (offline)"
            fi
        fi
    done

    _r_sep
    _r_line_c w b "FOLDER"
    _r_sep
    _r_line "  $SYNCCTL_FOLDER_ID"
    _r_sep
    _r_line_c w b "CHECKPOINT"
    _r_sep
    if [[ -n "$last_ckpt" ]]; then
        local id result ts
        id="$(syncctl_jq -r '.id' "$last_ckpt" 2>/dev/null)"
        result="$(syncctl_jq -r '.result' "$last_ckpt" 2>/dev/null)"
        ts="$(syncctl_jq -r '.timestamp' "$last_ckpt" 2>/dev/null)"
        if [[ "$result" == "pass" ]]; then
            _r_line_c 46 b "  #$id  ✓ CLEAN  $ts"
        else
            _r_line_c 196 b "  #$id  ✗ FAILED  $ts"
        fi
    else
        _r_line_c 226 "" "  (none yet)"
    fi

    _r_sep
    _r_line_c w b "STATE"
    _r_sep
    if [[ "$source" == "conflict" ]]; then
        _r_line_c 196 b "  ● STATE CONFLICT (FAIL CLOSED)"
    elif [[ -n "$master" ]]; then
        _r_line_c 46 b "  ● CLEAN  (source: $source)"
    else
        _r_line_c 226 "" "  ● UNINITIALIZED"
    fi
    _r_bot
    printf '\n'
}

render_who() {
    local line master source
    line="$(state_reconcile_master)"
    master="${line#master=}"
    master="${master%%|*}"
    source="${line#*source=}"
    source="${source%%|*}"

    if [[ "$source" == "conflict" ]]; then
        echo "⛔ OWNERSHIP CONFLICT (local != synced)"
        return 1
    fi
    if [[ -z "$master" ]]; then
        echo "(uninitialized)"
        return 1
    fi
    echo "MASTER: $master"
}

render_checkpoint() {
    local id="$1" result="$2" duration="$3"
    if [[ "$result" == "pass" ]]; then
        printf '\n'
        cn w b "CHECKPOINT #${id}"
        printf '\n'
        cn 46 b "✓ Local state"
        cn 46 b "✓ Syncthing state"
        cn 46 b "✓ Cluster state"
        cn 46 b "✓ Conflict check"
        cn 46 b "✓ Folder types"
        printf '\n'
        printf '%s  (%sms)\n' "$(c 46 b 'CHECKPOINT PASSED')" "$duration"
    else
        printf '\n'
        cn 196 b "⛔ CHECKPOINT FAILED"
        printf '\n'
        printf '  %s\n' "$(cn 196 b "Reason: $SYNCCTL_CHECKPOINT_REASON")"
        printf '  Master remains: %s\n' "$(state_reconcile_master | sed -n 's/^master=//p' | cut -d'|' -f1)"
    fi
}

render_conflicts() {
    local count=0
    cn w b "CONFLICTS"
    while IFS= read -r f; do
        (( count++ )) || true
        local size
        size="$(du -h "$f" 2>/dev/null | cut -f1)"
        printf '  %s  %s  (%s)\n' "$(c 226 b '⚠')" "$f" "$(c 244 "" "$size")"
    done < <(find "$SYNCCTL_FOLDER_ROOT" -name '*.sync-conflict-*' -type f 2>/dev/null)
    if (( count == 0 )); then
        printf '  %s\n' "$(cn 46 b '✓ no conflicts')"
    fi
    printf '\n  %s\n' "$(cn 244 "" "Total: $count")"
}

render_help() {
    cat <<EOF
$(c w b 'syncctl') — Syncthing ownership controller

$(c w b 'USAGE')
  syncctl [--debug] <command> [args]

$(c w b 'COMMANDS')
  status                          แสดง master + devices + checkpoint
  who                             แสดง master (text only)
  checkpoint                      ตรวจ + สร้าง checkpoint
  transfer <device>               Safe handover (demotes old master first)
       [--reason "..."]           Reason (required for --force)
       [--dry-run]                Show what would happen
       [--force]                  Break-glass (master offline)
  lock | unlock                   Manual lock control
  init <device>                   First-time setup
  conflicts                       List .sync-conflict-* files
  resolve <file> --keep newer|master
                                  เลือก winner
  recover                         Recover from stale/interrupted handover
  doctor                          รัน audit ทุกอย่าง
  logs [tail N]                   ดู audit log
  help                            แสดง help

$(c w b 'EXAMPLES')
  $(c 244 '' '# First time')
  syncctl init wsl

  $(c 244 '' '# Daily checks')
  syncctl status
  syncctl checkpoint

  $(c 244 '' '# Move master to another device')
  syncctl transfer windows --dry-run
  syncctl transfer windows --reason "hotfix in 3worlds.sh"

  $(c 244 '' '# Master is dead, break-glass')
  syncctl transfer windows --force --reason "wsl-down-3-days"

$(c w b 'FILES')
  Local state:   $SYNCCTL_HOME
  Synced SSOT:   $SYNCCTL_SYNCED_MASTER_FILE
  Audit log:     $SYNCCTL_AUDIT_LOG
EOF
}
