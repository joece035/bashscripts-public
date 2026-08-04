#!/bin/bash
# ============================================================
# tests/run.sh — syncctl test suite (no real cluster needed)
# ============================================================
# All tests use mock-api.sh + JSON fixtures
# Run: bash tools/syncctl/tests/run.sh
# ============================================================

set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNCCTL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
LIB_DIR="$SYNCCTL_DIR/lib"
SSOT="${SSOT:-$HOME/bashscripts}"

# Test counters
PASS=0
FAIL=0
FAILED_TESTS=()

# Self-contained color helpers (safe under set -u)
_R_OK()    { printf '\033[32;1m%s\033[0m' "$*"; }
_R_ERR()   { printf '\033[31;1m%s\033[0m' "$*"; }
_R_INFO()  { printf '\033[36;1m%s\033[0m' "$*"; }
_R_DIM()   { printf '\033[90m%s\033[0m' "$*"; }
_R_BOLD()  { printf '\033[1m%s\033[0m' "$*"; }

cn() {
    local color="${1:-}" style="" text="${2:-}"
    if [[ $# -ge 3 ]]; then style="$2"; text="$3"; fi
    printf '\033[1m%s\033[0m\n' "$text"
}
c() {
    local color="${1:-}" style="" text="${2:-}"
    if [[ $# -ge 3 ]]; then style="$2"; text="$3"; fi
    printf '%s' "$text"
}

_assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        printf "  %s %s\n" "$(_R_OK "✓")" "$label"
        (( PASS++ )) || true
    else
        printf "  %s %s\n" "$(_R_ERR "✗")" "$label"
        printf "      expected: %q\n" "$expected"
        printf "      actual:   %q\n" "$actual"
        (( FAIL++ )) || true
        FAILED_TESTS+=("$label")
    fi
}

_assert_contains() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        printf "  %s %s\n" "$(_R_OK "✓")" "$label"
        (( PASS++ )) || true
    else
        printf "  %s %s\n" "$(_R_ERR "✗")" "$label"
        printf "      needle:   %q\n" "$needle"
        printf "      haystack: %q\n" "$haystack"
        (( FAIL++ )) || true
        FAILED_TESTS+=("$label")
    fi
}

_setup() {
    local fixture_name="$1"
    export SYNCCTL_HOME="$(mktemp -d)"
    export SYNCCTL_STATE="$SYNCCTL_HOME/state.json"
    export SYNCCTL_LOCK_FILE="$SYNCCTL_HOME/syncctl.lock"
    export SYNCCTL_AUDIT_LOG="$SYNCCTL_HOME/audit.log"
    export SYNCCTL_CHECKPOINT_DIR="$SYNCCTL_HOME/checkpoints"
    export SYNCCTL_CONFLICT_ARCHIVE="$SYNCCTL_HOME/conflicts"
    export SYNCCTL_LOCAL_MASTER_FILE="$SYNCCTL_HOME/master"
    export SYNCCTL_FOLDER_ROOT="$(mktemp -d)"
    export SYNCCTL_SYNCED_MASTER_DIR="$SYNCCTL_FOLDER_ROOT/.syncctl"
    export SYNCCTL_SYNCED_MASTER_FILE="$SYNCCTL_SYNCED_MASTER_DIR/master"
    export SYNCCTL_MOCK_DIR="$TESTS_DIR/fixtures/$fixture_name"
    export JOE_ENV="WSL"

    source "$LIB_DIR/config.sh"
    source "$LIB_DIR/state.sh"
    source "$LIB_DIR/checkpoint.sh"
    source "$LIB_DIR/ownership.sh"
    source "$LIB_DIR/handover.sh"
    source "$LIB_DIR/renderer.sh"
    source "$LIB_DIR/doctor.sh"

    unset SYNCCTL_DEVICES SYNCCTL_API_URLS SYNCCTL_API_KEYS

    declare -gA SYNCCTL_DEVICES=(
        [wsl]="3S42YWK-FAKE-WSL-ID"
        [windows]="FJXVHAJ-FAKE-WIN-ID"
        [termux]="2KJ2HQ3-FAKE-TM-ID"
    )
    declare -gA SYNCCTL_API_URLS=(
        [wsl]="http://wsl:8385"
        [windows]="http://window:8384"
        [termux]="http://termux:8383"
    )
    declare -gA SYNCCTL_API_KEYS=(
        [wsl]="fake-wsl-key"
        [windows]="fake-win-key"
        [termux]="fake-tm-key"
    )
    export SYNCCTL_LOCAL_DEVICE="wsl"
    export SYNCCTL_LOCAL_API_URL="http://wsl:8385"
    export SYNCCTL_LOCAL_API_KEY="fake-wsl-key"

    source "$LIB_DIR/mock.sh"
}

_teardown() {
    rm -rf "$SYNCCTL_HOME" "$SYNCCTL_FOLDER_ROOT" 2>/dev/null
    unset SYNCCTL_DEVICES SYNCCTL_API_URLS SYNCCTL_API_KEYS
    unset _SYNCCTL_LOCK_DIR
}

# ──────────────────────────────────────────────────────────
# Test 1: status on clean cluster (WSL = master)
# ──────────────────────────────────────────────────────────
test_status_clean() {
    printf "\n%s\n" "$(_R_BOLD "TEST: status (clean cluster, WSL master)")"
    _setup "cluster-clean"

    state_set_local_master "wsl"

    local out
    out="$(render_status 2>&1)"
    _assert_contains "shows wsl as master" "wsl" "$out"
    _assert_contains "shows MASTER role" "MASTER" "$out"
    _assert_contains "shows folder type sendonly" "sendonly" "$out"
    _assert_contains "shows checkpoint section" "CHECKPOINT" "$out"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 2: who command
# ──────────────────────────────────────────────────────────
test_who() {
    printf "\n%s\n" "$(_R_BOLD "TEST: who (returns master)")"
    _setup "cluster-clean"
    state_set_local_master "wsl"

    local out
    out="$(render_who)"
    _assert_eq "returns WSL" "MASTER: wsl" "$out"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 3: checkpoint on clean cluster → pass
# ──────────────────────────────────────────────────────────
test_checkpoint_pass() {
    printf "\n%s\n" "$(_R_BOLD "TEST: checkpoint (clean → pass)")"
    _setup "cluster-clean"
    state_set_local_master "wsl"

    if checkpoint_run "wsl"; then
        printf "  %s checkpoint returns 0\n" "$(_R_OK "✓")"
        (( PASS++ )) || true
    else
        printf "  %s checkpoint should pass\n" "$(_R_ERR "✗")"
        (( FAIL++ )) || true
    fi
    _assert_eq "checkpoint ID is 4-digit" "0001" "$SYNCCTL_CHECKPOINT_ID"
    _assert_eq "result is pass" "pass" "$SYNCCTL_CHECKPOINT_RESULT"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 4: checkpoint fail → no master change
# ──────────────────────────────────────────────────────────
test_checkpoint_fail() {
    printf "\n%s\n" "$(_R_BOLD "TEST: checkpoint fail → no master change")"
    _setup "cluster-conflict"
    state_set_local_master "wsl"

    touch "$SYNCCTL_FOLDER_ROOT/test.sync-conflict-2026-08-03-120000.sh"

    if checkpoint_run "wsl"; then
        printf "  %s checkpoint should FAIL\n" "$(_R_ERR "✗")"
        (( FAIL++ )) || true
    else
        printf "  %s checkpoint correctly fails\n" "$(_R_OK "✓")"
        (( PASS++ )) || true
    fi
    _assert_eq "result is fail" "fail" "$SYNCCTL_CHECKPOINT_RESULT"

    local m; m="$(state_get_local_master)"
    _assert_eq "master unchanged" "wsl" "$m"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 5: transfer dry-run
# ──────────────────────────────────────────────────────────
test_transfer_dry_run() {
    printf "\n%s\n" "$(_R_BOLD "TEST: transfer --dry-run")"
    _setup "cluster-clean"
    state_set_local_master "wsl"

    local out
    out="$(transfer_master windows --dry-run 2>&1)"
    _assert_contains "shows DRY RUN" "DRY RUN" "$out"
    _assert_contains "shows current master" "wsl" "$out"
    _assert_contains "shows target" "windows" "$out"
    _assert_contains "shows no changes applied" "No changes applied" "$out"

    local m; m="$(state_get_local_master)"
    _assert_eq "master unchanged after dry-run" "wsl" "$m"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 6: transfer idempotency
# ──────────────────────────────────────────────────────────
test_transfer_idempotent() {
    printf "\n%s\n" "$(_R_BOLD "TEST: transfer to same device = noop")"
    _setup "cluster-clean"
    state_set_local_master "wsl"

    local out
    out="$(transfer_master wsl 2>&1)"
    _assert_contains "says already master" "already MASTER" "$out"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 7: full transfer (WSL → windows)
# ──────────────────────────────────────────────────────────
test_full_transfer() {
    printf "\n%s\n" "$(_R_BOLD "TEST: full transfer (wsl → windows)")"
    _setup "cluster-clean"
    state_set_local_master "wsl"

    if transfer_master windows --reason "test" 2>&1; then
        printf "  %s transfer returns 0\n" "$(_R_OK "✓")"
        (( PASS++ )) || true
    else
        printf "  %s transfer should succeed\n" "$(_R_ERR "✗")"
        (( FAIL++ )) || true
    fi

    local m; m="$(state_get_local_master)"
    _assert_eq "master is now windows" "windows" "$m"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 8: lock prevents concurrent
# ──────────────────────────────────────────────────────────
test_lock() {
    printf "\n%s\n" "$(_R_BOLD "TEST: lock prevents concurrent access")"
    _setup "cluster-clean"

    if lock_acquire; then
        printf "  %s first lock acquired\n" "$(_R_OK "✓")"
        (( PASS++ )) || true
    else
        printf "  %s first lock should succeed\n" "$(_R_ERR "✗")"
        (( FAIL++ )) || true
    fi

    if lock_acquire; then
        printf "  %s second lock should FAIL\n" "$(_R_ERR "✗")"
        (( FAIL++ )) || true
    else
        printf "  %s second lock correctly rejected\n" "$(_R_OK "✓")"
        (( PASS++ )) || true
    fi

    lock_release
    if lock_acquire; then
        printf "  %s can re-acquire after release\n" "$(_R_OK "✓")"
        (( PASS++ )) || true
        lock_release
    fi

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 9: state reconcile (fail closed on conflict)
# ──────────────────────────────────────────────────────────
test_state_reconcile() {
    printf "\n%s\n" "$(_R_BOLD "TEST: state reconcile (fail closed on conflict)")"
    _setup "cluster-clean"

    # Both empty
    local r; r="$(state_reconcile_master)"
    _assert_contains "uninit when both empty" "uninitialized" "$r"

    # Only local
    state_set_local_master "wsl"
    r="$(state_reconcile_master)"
    _assert_contains "local only" "master=wsl" "$r"

    # Both same
    state_set_synced_master "wsl"
    r="$(state_reconcile_master)"
    _assert_contains "both same" "master=wsl" "$r"

    # Disagree → MUST NOT auto-reconcile, MUST return source=conflict
    state_set_synced_master "windows"
    r="$(state_reconcile_master)"
    _assert_contains "disagree → source=conflict" "source=conflict" "$r"
    _assert_contains "disagree → keeps local_was" "local_was=wsl" "$r"
    _assert_contains "disagree → keeps synced_was" "synced_was=windows" "$r"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 10: ownership conflict aborts transfer
# ──────────────────────────────────────────────────────────
test_ownership_conflict_abort() {
    printf "\n%s\n" "$(_R_BOLD "TEST: ownership conflict aborts transfer")"
    _setup "cluster-clean"

    state_set_local_master "wsl"
    state_set_synced_master "windows"

    local out
    if out="$(transfer_master windows 2>&1)"; then
        printf "  %s transfer should FAIL on state conflict\n" "$(_R_ERR "✗")"
        (( FAIL++ )) || true
    else
        printf "  %s transfer correctly aborted on state conflict\n" "$(_R_OK "✓")"
        (( PASS++ )) || true
    fi
    _assert_contains "reports conflict banner" "OWNERSHIP STATE CONFLICT" "$out"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Test 11: doctor
# ──────────────────────────────────────────────────────────
test_doctor() {
    printf "\n%s\n" "$(_R_BOLD "TEST: doctor runs without error")"
    _setup "cluster-clean"
    state_set_local_master "wsl"

    local out
    out="$(doctor_run 2>&1)"
    _assert_contains "doctor prints banner" "syncctl doctor" "$out"
    _assert_contains "doctor checks CRLF" "CRLF" "$out"
    _assert_contains "doctor checks master" "Master state" "$out"
    _assert_contains "doctor checks API" "API reachability" "$out"

    _teardown
}

# ──────────────────────────────────────────────────────────
# Run all
# ──────────────────────────────────────────────────────────
main() {
    printf "%s\n" "$(_R_BOLD "═══════════════════════════════════════════════════════════")"
    printf "%s\n" "$(_R_BOLD "  syncctl test suite")"
    printf "%s\n" "$(_R_BOLD "═══════════════════════════════════════════════════════════")"

    test_status_clean
    test_who
    test_checkpoint_pass
    test_checkpoint_fail
    test_transfer_dry_run
    test_transfer_idempotent
    test_full_transfer
    test_lock
    test_state_reconcile
    test_ownership_conflict_abort
    test_doctor

    printf "\n%s\n" "$(_R_BOLD "═══════════════════════════════════════════════════════════")"
    if (( FAIL == 0 )); then
        printf "%s\n" "$(_R_OK "  All $PASS tests passed ✓")"
        exit 0
    else
        printf "%s\n" "$(_R_ERR "  $PASS passed, $FAIL FAILED")"
        printf "%s\n" "$(_R_DIM "  Failed: ${FAILED_TESTS[*]}")"
        exit 1
    fi
}

main
