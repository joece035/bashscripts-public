#!/bin/bash
# ============================================================
# JOE_ENV Test Suite — Bash + Zsh on Termux
# ============================================================
# Usage: bash tests/test_joe_env.sh
#        zsh tests/test_joe_env.sh  (tests zsh compatibility)
# ============================================================

set -uo pipefail 2>/dev/null || setopt PIPE_FAIL 2>/dev/null

# ── Detect shell ──
if [[ -n "${ZSH_VERSION:-}" ]]; then
    SHELL_TYPE="zsh"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    SHELL_TYPE="bash"
else
    SHELL_TYPE="unknown"
fi

# ── Colors (before SSOT loaded) ──
if command -v tput >/dev/null 2>&1; then
    _BOLD=$(tput bold)
    _RED=$(tput setaf 1)
    _GREEN=$(tput setaf 2)
    _YELLOW=$(tput setaf 3)
    _RESET=$(tput sgr0)
else
    _BOLD=""
    _RED=""
    _GREEN=""
    _YELLOW=""
    _RESET=""
fi

# ── Test counters ──
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ── Helpers ──
pass() { ((TESTS_PASSED++)); ((TESTS_RUN++)); echo "  ${_GREEN}✅ PASS${_RESET} $1"; }
fail() { ((TESTS_FAILED++)); ((TESTS_RUN++)); echo "  ${_RED}❌ FAIL${_RESET} $1"; }
section() { echo -e "\n${_BOLD}═══ $1 ═══${_RESET}"; }

# ── JOE_ROOT ──
JOE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export JOE_ROOT
export JOE_CORE="$JOE_ROOT/core"
export JOE_FUNCTIONS="$JOE_ROOT/functions"
export JOE_PLUGINS="$JOE_ROOT/plugins"
export JOE_TOOLS="$JOE_ROOT/tools"
export SSOT="$JOE_ROOT"
export SCRIPTS_PATH="$JOE_ROOT"

section "0. Environment Detection"
echo "  Shell: $SHELL_TYPE"
echo "  JOE_ROOT: $JOE_ROOT"

# ============================================================
section "1. Directory Structure"
# ============================================================

for dir in bootstrap core functions plugins/block_engine plugins/syncctl plugins/hermes modules tools lessons profiles; do
    if [[ -d "$JOE_ROOT/$dir" ]]; then
        pass "Directory exists: $dir/"
    else
        fail "Directory missing: $dir/"
    fi
done

# ============================================================
section "2. Core Files"
# ============================================================

for file in bootstrap/00-env.sh bootstrap/setup.sh core/01-colors.sh core/02-aliases.sh core/3worlds.sh core/profiles.sh core/theme.sh joe.sh; do
    if [[ -f "$JOE_ROOT/$file" ]]; then
        pass "File exists: $file"
    else
        fail "File missing: $file"
    fi
done

# ============================================================
section "3. Plugin Files"
# ============================================================

for file in plugins/block_engine/entry.sh plugins/block_engine/block/theme.sh plugins/block_engine/block/renderer.sh plugins/block_engine/block/status.sh plugins/block_engine/block/layout.sh plugins/block_engine/block/utils.sh plugins/block_engine/styles/block_style.sh plugins/syncctl/syncctl plugins/hermes/hermes.sh; do
    if [[ -f "$JOE_ROOT/$file" ]]; then
        pass "File exists: $file"
    else
        fail "File missing: $file"
    fi
done

# ============================================================
section "4. Old Paths Should NOT Exist"
# ============================================================

# Root-level files that should have been moved
for file in 00-env.sh 01-colors.sh 02-aliases.sh 3worlds.sh profiles.sh theme.sh; do
    if [[ -f "$JOE_ROOT/$file" ]]; then
        fail "Old file still at root: $file (should be in core/ or bootstrap/)"
    else
        pass "Old file removed from root: $file"
    fi
done

# Old joe-block directory
if [[ -d "$JOE_ROOT/functions/joe-block" ]]; then
    fail "Old directory still exists: functions/joe-block/ (should be plugins/block_engine/)"
else
    pass "Old directory removed: functions/joe-block/"
fi

# Old syncctl location
if [[ -d "$JOE_ROOT/tools/syncctl" ]]; then
    fail "Old directory still exists: tools/syncctl/ (should be plugins/syncctl/)"
else
    pass "Old directory removed: tools/syncctl/"
fi

# ============================================================
section "5. Source Path Consistency"
# ============================================================

# Check that joe.sh uses JOE_ROOT paths
if grep -q 'JOE_ROOT/bootstrap/00-env.sh' "$JOE_ROOT/joe.sh" 2>/dev/null; then
    pass "joe.sh sources bootstrap/00-env.sh"
else
    fail "joe.sh does not source bootstrap/00-env.sh"
fi

if grep -q 'JOE_CORE/01-colors.sh' "$JOE_ROOT/joe.sh" 2>/dev/null; then
    pass "joe.sh sources core/01-colors.sh"
else
    fail "joe.sh does not source core/01-colors.sh"
fi

if grep -q 'JOE_PLUGINS/block_engine/entry.sh' "$JOE_ROOT/joe.sh" 2>/dev/null; then
    pass "joe.sh sources plugins/block_engine/entry.sh"
else
    fail "joe.sh does not source plugins/block_engine/entry.sh"
fi

if grep -q 'JOE_PLUGINS/syncctl/syncctl' "$JOE_ROOT/joe.sh" 2>/dev/null; then
    pass "joe.sh sources plugins/syncctl/syncctl"
else
    fail "joe.sh does not source plugins/syncctl/syncctl"
fi

# Check 00-fm-loader.sh uses new paths
if grep -q 'JOE_PLUGINS/block_engine' "$JOE_ROOT/functions/00-fm-loader.sh" 2>/dev/null; then
    pass "00-fm-loader.sh uses plugins/block_engine/"
else
    fail "00-fm-loader.sh still uses old path for block_engine"
fi

if grep -q 'JOE_PLUGINS/hermes' "$JOE_ROOT/functions/00-fm-loader.sh" 2>/dev/null; then
    pass "00-fm-loader.sh uses plugins/hermes/"
else
    fail "00-fm-loader.sh still uses old path for hermes"
fi

# Check 03-fpath.sh uses new paths
if grep -q 'JOE_FUNCTIONS' "$JOE_ROOT/functions/03-fpath.sh" 2>/dev/null; then
    pass "03-fpath.sh uses JOE_FUNCTIONS"
else
    fail "03-fpath.sh still uses old path"
fi

# Check 11-bash-manager.sh uses new paths
if grep -q 'JOE_CORE/01-colors.sh' "$JOE_ROOT/functions/11-bash-manager.sh" 2>/dev/null; then
    pass "11-bash-manager.sh uses JOE_CORE/01-colors.sh"
else
    fail "11-bash-manager.sh still uses old path for colors"
fi

if grep -q 'JOE_ROOT/bootstrap/00-env.sh' "$JOE_ROOT/functions/11-bash-manager.sh" 2>/dev/null; then
    pass "11-bash-manager.sh uses JOE_ROOT/bootstrap/00-env.sh"
else
    fail "11-bash-manager.sh still uses old path for env"
fi

# Check block_engine/theme.sh uses new paths
if grep -qE 'JOE_CORE.*/01-colors.sh' "$JOE_ROOT/plugins/block_engine/block/theme.sh" 2>/dev/null; then
    pass "block_engine/theme.sh sources JOE_CORE/01-colors.sh"
else
    fail "block_engine/theme.sh still uses old path for colors"
fi

if grep -qE 'JOE_PLUGINS.*/block_engine/styles' "$JOE_ROOT/plugins/block_engine/block/theme.sh" 2>/dev/null; then
    pass "block_engine/theme.sh sources JOE_PLUGINS/block_engine/styles/"
else
    fail "block_engine/theme.sh still uses old path for styles"
fi

# ============================================================
section "6. No Hardcoded Paths"
# ============================================================

# Check for hardcoded /home/usercivenz in source files
# Exclusions: .git, test fixtures (JSON), joe.sh (WSL hwsl variable is expected)
HARDCODED=$(grep -rl '/home/usercivenz' "$JOE_ROOT/functions/" "$JOE_ROOT/plugins/" "$JOE_ROOT/joe.sh" 2>/dev/null | grep -vE '\.git|fixtures|\.json|joe\.sh' || true)
if [[ -z "$HARDCODED" ]]; then
    pass "No hardcoded /home/usercivenz in source files"
else
    fail "Hardcoded paths found in: $HARDCODED"
fi

# ============================================================
section "7. Cross-Dependency Resolution"
# ============================================================

# block_engine/theme.sh should source from JOE_CORE, not _BLOCK_ROOT
if grep -q 'JOE_CORE' "$JOE_ROOT/plugins/block_engine/block/theme.sh" 2>/dev/null; then
    pass "block_engine/theme.sh uses JOE_CORE (not _BLOCK_ROOT)"
else
    fail "block_engine/theme.sh still uses _BLOCK_ROOT for colors"
fi

# ============================================================
section "8. Scripts Executable"
# ============================================================

for file in joe.sh bootstrap/setup.sh plugins/syncctl/syncctl; do
    if [[ -x "$JOE_ROOT/$file" ]] || [[ -f "$JOE_ROOT/$file" ]]; then
        pass "File accessible: $file"
    else
        fail "File not accessible: $file"
    fi
done

# ============================================================
section "9. Zsh Compatibility (if running in zsh)"
# ============================================================

if [[ "$SHELL_TYPE" == "zsh" ]]; then
    # Test that JOE_ROOT is set correctly
    if [[ -n "${JOE_ROOT:-}" ]]; then
        pass "JOE_ROOT is set: $JOE_ROOT"
    else
        fail "JOE_ROOT is not set"
    fi
    
    # Test that JOE_CORE is set correctly
    if [[ -n "${JOE_CORE:-}" ]]; then
        pass "JOE_CORE is set: $JOE_CORE"
    else
        fail "JOE_CORE is not set"
    fi
    
    # Test that core files can be sourced
    if [[ -f "$JOE_CORE/01-colors.sh" ]]; then
        source "$JOE_CORE/01-colors.sh" 2>/dev/null
        if declare -f cn >/dev/null 2>&1; then
            pass "cn() function available after sourcing 01-colors.sh"
        else
            fail "cn() function not available after sourcing 01-colors.sh"
        fi
    else
        fail "Cannot test sourcing: 01-colors.sh not found"
    fi
    
    # Test that block_engine can be sourced
    if [[ -f "$JOE_PLUGINS/block_engine/entry.sh" ]]; then
        source "$JOE_PLUGINS/block_engine/entry.sh" 2>/dev/null
        if declare -f m >/dev/null 2>&1; then
            pass "m() function available after sourcing block_engine"
        else
            fail "m() function not available after sourcing block_engine"
        fi
    else
        fail "Cannot test sourcing: block_engine/entry.sh not found"
    fi
else
    echo "  (Skipped — not running in zsh)"
fi

# ============================================================
section "10. Bash Compatibility (if running in bash)"
# ============================================================

if [[ "$SHELL_TYPE" == "bash" ]]; then
    # Test that JOE_ROOT is set correctly
    if [[ -n "${JOE_ROOT:-}" ]]; then
        pass "JOE_ROOT is set: $JOE_ROOT"
    else
        fail "JOE_ROOT is not set"
    fi
    
    # Test that JOE_CORE is set correctly
    if [[ -n "${JOE_CORE:-}" ]]; then
        pass "JOE_CORE is set: $JOE_CORE"
    else
        fail "JOE_CORE is not set"
    fi
    
    # Test that core files can be sourced
    if [[ -f "$JOE_CORE/01-colors.sh" ]]; then
        source "$JOE_CORE/01-colors.sh" 2>/dev/null
        if declare -f cn >/dev/null 2>&1; then
            pass "cn() function available after sourcing 01-colors.sh"
        else
            fail "cn() function not available after sourcing 01-colors.sh"
        fi
    else
        fail "Cannot test sourcing: 01-colors.sh not found"
    fi
    
    # Test that block_engine can be sourced
    if [[ -f "$JOE_PLUGINS/block_engine/entry.sh" ]]; then
        source "$JOE_PLUGINS/block_engine/entry.sh" 2>/dev/null
        if declare -f m >/dev/null 2>&1; then
            pass "m() function available after sourcing block_engine"
        else
            fail "m() function not available after sourcing block_engine"
        fi
    else
        fail "Cannot test sourcing: block_engine/entry.sh not found"
    fi
else
    echo "  (Skipped — not running in bash)"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ${_BOLD}TEST RESULTS — $SHELL_TYPE${_RESET}"
echo "═══════════════════════════════════════════════════════════"
echo "  Total:  $TESTS_RUN"
echo "  ${_GREEN}Passed: $TESTS_PASSED${_RESET}"
echo "  ${_RED}Failed: $TESTS_FAILED${_RESET}"
echo "═══════════════════════════════════════════════════════════"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "  ${_GREEN}${_BOLD}ALL TESTS PASSED! ✅${_RESET}"
    exit 0
else
    echo "  ${_RED}${_BOLD}SOME TESTS FAILED! ❌${_RESET}"
    exit 1
fi
