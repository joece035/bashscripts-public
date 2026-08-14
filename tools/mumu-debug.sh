#!/bin/bash
# ============================================================
# mumu-debug.sh — MUMU Environment Debugger
# ============================================================
# Usage:  mumu-debug.sh [all|env|ssh|micro|zsh|joe|sync]
#         mumu-debug.sh --fix [micro|zsh|joe]  (auto-fix mode)
#
# SSOT: ~/bashscripts/01-colors.sh (c/cn/color)
# Deps: ssh, curl, color functions from joe.sh
# ============================================================

# ── Color helpers (standalone mode — works without joe.sh) ──
if ! type -t c &>/dev/null; then
    _c() { printf '\e[38;5;%sm' "$1"; }
    _r() { printf '\e[0m'; }
    c() {
        local color="$1"; shift
        local style=""
        if [[ "$1" =~ ^[bdiu]{1,4}$ ]]; then
            style="$1"; shift
        fi
        local prefix=""
        case "${style}" in
            *b*) prefix+="\e[1m" ;;
            *d*) prefix+="\e[2m" ;;
            *i*) prefix+="\e[3m" ;;
            *u*) prefix+="\e[4m" ;;
        esac
        printf "${prefix}$(_c "$color")%s$(_r)" "$*"
    }
    cn() { c "$@"; printf '\n'; }
fi

# ── Config ──
MUMU_HOST="${NODE_MUMU_HOST:-${mumu:-100.100.176.94}}"
MUMU_PORT="${NODE_MUMU_PORT:-${SSH_MUMU_PORT:-8022}}"
MUMU_USER="${NODE_MUMU_USER:-u0_a62}"
MUMU_KEY="${HOME}/.ssh/id_ed25519_mumu"
JOE_ROOT="${JOE_ROOT:-$HOME/bashscripts}"

# ── Counters ──
PASS=0; FAIL=0; WARN=0; FIXES=0

# ── Helpers ──
_pass() { ((PASS++)); cn 46 "  ✔ $1"; }
_fail() { ((FAIL++)); cn 196 "  ✘ $1"; }
_warn() { ((WARN++)); cn 214 "  ⚠ $1"; }
_fix()  { ((FIXES++)); cn 82 "  🔧 $1"; }
_hdr()  { printf '\n'; cn 39 "═══ $1 ═══"; }
_info() { cn 252 "  ℹ $1"; }

summary() {
    printf '\n'
    cn 45 "═══════════════════════════════════════════════"
    cn 226 "  SUMMARY"
    cn 45 "═══════════════════════════════════════════════"
    c  46 "  ✔ PASS: $PASS   "; c 214 "⚠ WARN: $WARN   "; cn 196 "✘ FAIL: $FAIL"
    if (( FIXES > 0 )); then
        cn 82 "  🔧 Fixes applied: $FIXES"
    fi
    if (( FAIL > 0 )); then
        cn 208 "  → Some checks failed. Review output above."
    elif (( WARN > 0 )); then
        cn 226 "  → All critical checks passed, but some warnings."
    else
        cn 46 "  → All checks passed! 🎉"
    fi
    printf '\n'
}

# ============================================================
# MODULE: ENV — Local environment validation
# ============================================================
mod_env() {
    _hdr "LOCAL ENVIRONMENT"

    # JOE_ENV
    if [[ -n "${JOE_ENV:-}" ]]; then
        _pass "JOE_ENV=$JOE_ENV"
    else
        _fail "JOE_ENV not set — source joe.sh first"
    fi

    # JOE_ROOT
    if [[ -d "${JOE_ROOT:-}" ]]; then
        _pass "JOE_ROOT=$JOE_ROOT"
    else
        _fail "JOE_ROOT=$JOE_ROOT — directory not found"
    fi

    # 01-colors.sh
    if [[ -f "$JOE_ROOT/core/01-colors.sh" ]]; then
        _pass "01-colors.sh exists"
    else
        _fail "01-colors.sh not found at $JOE_ROOT/core/"
    fi

    # SSH keys
    if [[ -f "$MUMU_KEY" ]]; then
        _pass "SSH key: $MUMU_KEY"
    else
        _warn "SSH key $MUMU_KEY not found — will try default"
    fi

    # Tailscale
    if command -v tailscale &>/dev/null; then
        local ts_ip
        ts_ip=$(tailscale ip -4 2>/dev/null)
        if [[ -n "$ts_ip" ]]; then
            _pass "Tailscale active: $ts_ip"
        else
            _warn "Tailscale installed but not connected"
        fi
    else
        _warn "Tailscale not installed"
    fi

    # SSH agent
    if ssh-add -l &>/dev/null 2>&1 || [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        _pass "SSH agent active"
    else
        _warn "SSH agent not running"
    fi
}

# ============================================================
# MODULE: SSH — MUMU connectivity test
# ============================================================
mod_ssh() {
    _hdr "SSH → MUMU ($MUMU_USER@$MUMU_HOST:$MUMU_PORT)"

    # Build SSH command
    local ssh_opts=(-p "$MUMU_PORT" -o ConnectTimeout=8 -o BatchMode=yes)
    if [[ -f "$MUMU_KEY" ]]; then
        ssh_opts+=(-i "$MUMU_KEY")
    fi

    # Test 1: Ping (Tailscale)
    if command -v ping &>/dev/null; then
        if ping -c 1 -W 3 "$MUMU_HOST" &>/dev/null; then
            _pass "Ping $MUMU_HOST reachable"
        else
            _fail "Ping $MUMU_HOST unreachable"
        fi
    fi

    # Test 2: SSH connection
    if ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" echo "SSH_OK" 2>/dev/null | grep -q "SSH_OK"; then
        _pass "SSH connection successful"
    else
        _fail "SSH connection failed"
        _info "Try: ssh -p $MUMU_PORT -i $MUMU_KEY $MUMU_USER@$MUMU_HOST"
        return 1
    fi

    # Test 3: Remote shell
    local remote_shell
    remote_shell=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" 'echo $SHELL' 2>/dev/null)
    if [[ -n "$remote_shell" ]]; then
        _pass "Remote shell: $remote_shell"
    else
        _warn "Cannot detect remote shell"
    fi

    # Test 4: Remote uname
    local remote_uname
    remote_uname=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" 'uname -a' 2>/dev/null)
    if [[ -n "$remote_uname" ]]; then
        _info "Remote: $remote_uname"
    fi
}

# ============================================================
# MODULE: MICRO — Micro editor diagnostics
# ============================================================
mod_micro() {
    _hdr "MICRO EDITOR (remote)"

    local ssh_opts=(-p "$MUMU_PORT" -o ConnectTimeout=8 -o BatchMode=yes)
    [[ -f "$MUMU_KEY" ]] && ssh_opts+=(-i "$MUMU_KEY")

    local remote_cmd='
        echo "=== MICRO_BINARY ==="
        which micro 2>&1 || echo "NOT_FOUND"
        micro --version 2>&1 || echo "NO_VERSION"

        echo "=== MICRO_CONFIG ==="
        ls -la ~/.config/micro/ 2>&1 || echo "NO_CONFIG_DIR"

        echo "=== MICRO_SETTINGS ==="
        cat ~/.config/micro/settings.json 2>&1 || echo "NO_SETTINGS"

        echo "=== MICRO_PLUGINS ==="
        ls ~/.config/micro/plug/ 2>&1 || echo "NO_PLUGINS_DIR"

        echo "=== MICRO_LOGS ==="
        tail -20 ~/.config/micro/log.txt 2>&1 || echo "NO_LOG"

        echo "=== MICRO_SYNTAX ==="
        zsh -n ~/.config/micro/settings.json 2>&1 || true
    '

    local output
    output=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" "$remote_cmd" 2>/dev/null)

    if [[ -z "$output" ]]; then
        _fail "Cannot retrieve micro info — SSH may have failed"
        return 1
    fi

    # Parse output
    local binary
    binary=$(echo "$output" | sed -n '/=== MICRO_BINARY ===/,/=== MICRO_CONFIG ===/p' | tail -n +2 | head -1)
    if [[ "$binary" == "NOT_FOUND" ]]; then
        _fail "micro not installed"
        _info "Fix: pkg install micro (Termux) or pkg install micro (MUMU)"
    elif [[ -n "$binary" ]]; then
        _pass "micro found: $binary"
        local ver
        ver=$(echo "$output" | sed -n '/=== MICRO_BINARY ===/,/=== MICRO_CONFIG ===/p' | sed -n '2p')
        [[ -n "$ver" ]] && _info "Version: $ver"
    fi

    local config_dir
    config_dir=$(echo "$output" | sed -n '/=== MICRO_CONFIG ===/,/=== MICRO_SETTINGS ===/p' | tail -n +2 | head -1)
    if [[ "$config_dir" == *"No such file"* ]] || [[ "$config_dir" == "NO_CONFIG_DIR" ]]; then
        _warn "No micro config directory"
    else
        _pass "Config dir exists"
        echo "$output" | sed -n '/=== MICRO_CONFIG ===/,/=== MICRO_SETTINGS ===/p' | tail -n +2 | head -5 | while IFS= read -r line; do
            [[ -n "$line" ]] && _info "$line"
        done
    fi

    local settings
    settings=$(echo "$output" | sed -n '/=== MICRO_SETTINGS ===/,/=== MICRO_PLUGINS ===/p' | tail -n +2 | head -1)
    if [[ "$settings" == "NO_SETTINGS" ]]; then
        _warn "No settings.json — will be created on first run"
    elif [[ "$settings" == *"No such file"* ]]; then
        _warn "settings.json missing"
    else
        _pass "settings.json exists"
        # Check for common issues
        local raw
        raw=$(echo "$output" | sed -n '/=== MICRO_SETTINGS ===/,/=== MICRO_PLUGINS ===/p' | tail -n +2)
        if echo "$raw" | grep -q '"json"'; then
            _info "JSON syntax OK"
        fi
    fi

    local plugins
    plugins=$(echo "$output" | sed -n '/=== MICRO_PLUGINS ===/,/=== MICRO_LOGS ===/p' | tail -n +2 | head -1)
    if [[ "$plugins" == "NO_PLUGINS_DIR" ]] || [[ "$plugins" == *"No such file"* ]]; then
        _info "No plugins installed"
    else
        _pass "Plugins directory exists"
    fi

    local log_tail
    log_tail=$(echo "$output" | sed -n '/=== MICRO_LOGS ===/,/=== MICRO_SYNTAX ===/p' | tail -n +2 | head -1)
    if [[ "$log_tail" == "NO_LOG" ]]; then
        _info "No log file (good — no errors recorded)"
    else
        _warn "Recent log entries:"
        echo "$output" | sed -n '/=== MICRO_LOGS ===/,/=== MICRO_SYNTAX ===/p' | tail -n +2 | head -5 | while IFS= read -r line; do
            [[ -n "$line" ]] && c 248 "    $line"
            printf '\n'
        done
    fi
}

# ============================================================
# MODULE: ZSH — Zsh shell diagnostics
# ============================================================
mod_zsh() {
    _hdr "ZSH SHELL (remote)"

    local ssh_opts=(-p "$MUMU_PORT" -o ConnectTimeout=8 -o BatchMode=yes)
    [[ -f "$MUMU_KEY" ]] && ssh_opts+=(-i "$MUMU_KEY")

    local remote_cmd='
        echo "=== ZSH_VERSION ==="
        zsh --version 2>&1 || echo "NOT_FOUND"

        echo "=== ZSHRC_EXISTS ==="
        ls -la ~/.zshrc 2>&1 || echo "NO_ZSHRC"

        echo "=== ZSHRC_SYNTAX ==="
        zsh -n ~/.zshrc 2>&1 || echo "SYNTAX_ERROR"

        echo "=== ZSH_STARTUP_TEST ==="
        zsh --no-rcs -c "echo STARTUP_OK" 2>&1

        echo "=== ZSHRC_LINES ==="
        wc -l ~/.zshrc 2>&1 || echo "0"

        echo "=== OH_MY_ZSH ==="
        ls -la ~/.oh-my-zsh/oh-my-zsh.sh 2>&1 || echo "NO_OMZ"

        echo "=== P10K ==="
        ls -la ~/.p10k.zsh 2>&1 || echo "NO_P10K"

        echo "=== ZSHRC_CONTENT ==="
        head -50 ~/.zshrc 2>&1 || echo "EMPTY"

        echo "=== ZSHRC_SOURCES ==="
        grep -n "^source\|^\\." ~/.zshrc 2>&1 || echo "NO_SOURCES"

        echo "=== ZSHRC_ERRORS_VERBOSE ==="
        zsh -xvs ~/.zshrc 2>&1 | head -30 || echo "VERBOSE_OK"
    '

    local output
    output=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" "$remote_cmd" 2>/dev/null)

    if [[ -z "$output" ]]; then
        _fail "Cannot retrieve zsh info"
        return 1
    fi

    # Version
    local ver
    ver=$(echo "$output" | sed -n '/=== ZSH_VERSION ===/,/=== ZSHRC_EXISTS ===/p' | tail -n +2 | head -1)
    if [[ "$ver" == "NOT_FOUND" ]]; then
        _fail "zsh not installed"
        _info "Fix: pkg install zsh"
        return 1
    else
        _pass "zsh installed: $ver"
    fi

    # .zshrc
    local zshrc
    zshrc=$(echo "$output" | sed -n '/=== ZSHRC_EXISTS ===/,/=== ZSHRC_SYNTAX ===/p' | tail -n +2 | head -1)
    if [[ "$zshrc" == "NO_ZSHRC" ]] || [[ "$zshrc" == *"No such file"* ]]; then
        _fail ".zshrc not found"
        _info "Fix: cp ~/bashscripts/profiles/termux/.zshrc ~/.zshrc"
    else
        _pass ".zshrc exists"
    fi

    # Syntax check
    local syntax
    syntax=$(echo "$output" | sed -n '/=== ZSHRC_SYNTAX ===/,/=== ZSH_STARTUP_TEST ===/p' | tail -n +2 | head -1)
    if [[ "$syntax" == "SYNTAX_ERROR" ]]; then
        _fail ".zshrc has syntax errors"
        echo "$output" | sed -n '/=== ZSHRC_SYNTAX ===/,/=== ZSH_STARTUP_TEST ===/p' | tail -n +2 | head -3 | while IFS= read -r line; do
            c 196 "    $line"
            printf '\n'
        done
    elif [[ -n "$syntax" ]]; then
        _fail ".zshrc syntax error: $syntax"
    else
        _pass ".zshrc syntax OK"
    fi

    # Startup test
    local startup
    startup=$(echo "$output" | sed -n '/=== ZSH_STARTUP_TEST ===/,/=== ZSHRC_LINES ===/p' | tail -n +2 | head -1)
    if [[ "$startup" == "STARTUP_OK" ]]; then
        _pass "Zsh startup (no-rcs) OK"
    else
        _warn "Zsh startup issue: $startup"
    fi

    # Line count
    local lines
    lines=$(echo "$output" | sed -n '/=== ZSHRC_LINES ===/,/=== OH_MY_ZSH ===/p' | tail -n +2 | head -1)
    _info ".zshrc lines: ${lines:-unknown}"

    # Oh My Zsh
    local omz
    omz=$(echo "$output" | sed -n '/=== OH_MY_ZSH ===/,/=== P10K ===/p' | tail -n +2 | head -1)
    if [[ "$omz" == "NO_OMZ" ]] || [[ "$omz" == *"No such file"* ]]; then
        _warn "Oh My Zsh not installed"
    else
        _pass "Oh My Zsh installed"
    fi

    # Powerlevel10k
    local p10k
    p10k=$(echo "$output" | sed -n '/=== P10K ===/,/=== ZSHRC_CONTENT ===/p' | tail -n +2 | head -1)
    if [[ "$p10k" == "NO_P10K" ]] || [[ "$p10k" == *"No such file"* ]]; then
        _info "Powerlevel10k not installed (optional)"
    else
        _pass "Powerlevel10k installed"
    fi

    # Show sourced files
    _info "Sourced files in .zshrc:"
    echo "$output" | sed -n '/=== ZSHRC_SOURCES ===/,/=== ZSHRC_ERRORS_VERBOSE ===/p' | tail -n +2 | head -10 | while IFS= read -r line; do
        [[ -n "$line" ]] && c 252 "    $line"
        printf '\n'
    done
}

# ============================================================
# MODULE: JOE — Joe scripts validation
# ============================================================
mod_joe() {
    _hdr "JOE SCRIPTS (remote)"

    local ssh_opts=(-p "$MUMU_PORT" -o ConnectTimeout=8 -o BatchMode=yes)
    [[ -f "$MUMU_KEY" ]] && ssh_opts+=(-i "$MUMU_KEY")

    local remote_cmd='
        echo "=== JOE_DIR ==="
        ls -la ~/bashscripts/ 2>&1 | head -5 || echo "NO_JOE_DIR"

        echo "=== JOE_SH ==="
        ls -la ~/bashscripts/joe.sh 2>&1 || echo "NO_JOE_SH"

        echo "=== JOE_ENV ==="
        grep "JOE_ENV" ~/.bashrc ~/.zshrc 2>/dev/null | head -5 || echo "NO_JOE_ENV_IN_RC"

        echo "=== JOE_SOURCE_TEST ==="
        bash -c "source ~/bashscripts/joe.sh 2>&1 && echo JOE_OK || echo JOE_FAIL" 2>&1 | tail -5

        echo "=== 01_COLORS ==="
        ls -la ~/bashscripts/core/01-colors.sh 2>&1 || echo "NO_COLORS"

        echo "=== 3WORLDS ==="
        ls -la ~/bashscripts/core/3worlds.sh 2>&1 || echo "NO_3WORLDS"

        echo "=== TOOLS_DIR ==="
        ls ~/bashscripts/tools/ 2>&1 | head -10 || echo "NO_TOOLS"
    '

    local output
    output=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" "$remote_cmd" 2>/dev/null)

    if [[ -z "$output" ]]; then
        _fail "Cannot retrieve joe scripts info"
        return 1
    fi

    # Joe dir
    local joe_dir
    joe_dir=$(echo "$output" | sed -n '/=== JOE_DIR ===/,/=== JOE_SH ===/p' | tail -n +2 | head -1)
    if [[ "$joe_dir" == "NO_JOE_DIR" ]]; then
        _fail "~/bashscripts/ not found"
        _info "Fix: syncthing or git clone"
        return 1
    else
        _pass "~/bashscripts/ exists"
    fi

    # joe.sh
    local joe_sh
    joe_sh=$(echo "$output" | sed -n '/=== JOE_SH ===/,/=== JOE_ENV ===/p' | tail -n +2 | head -1)
    if [[ "$joe_sh" == "NO_JOE_SH" ]]; then
        _fail "joe.sh not found"
    else
        _pass "joe.sh exists"
    fi

    # JOE_ENV in rc
    local joe_env_rc
    joe_env_rc=$(echo "$output" | sed -n '/=== JOE_ENV ===/,/=== JOE_SOURCE_TEST ===/p' | tail -n +2 | head -1)
    if [[ "$joe_env_rc" == "NO_JOE_ENV_IN_RC" ]]; then
        _warn "JOE_ENV not set in .bashrc/.zshrc"
        _info "Ensure JOE_ENV is set before sourcing joe.sh"
    else
        _pass "JOE_ENV found in shell rc"
    fi

    # Source test
    local source_test
    source_test=$(echo "$output" | sed -n '/=== JOE_SOURCE_TEST ===/,/=== 01_COLORS ===/p' | tail -n +2 | head -1)
    if [[ "$source_test" == "JOE_OK" ]]; then
        _pass "joe.sh sources successfully"
    else
        _fail "joe.sh source failed"
        echo "$output" | sed -n '/=== JOE_SOURCE_TEST ===/,/=== 01_COLORS ===/p' | tail -n +2 | head -5 | while IFS= read -r line; do
            c 248 "    $line"
            printf '\n'
        done
    fi

    # Core files
    local colors_file
    colors_file=$(echo "$output" | sed -n '/=== 01_COLORS ===/,/=== 3WORLDS ===/p' | tail -n +2 | head -1)
    if [[ "$colors_file" == "NO_COLORS" ]]; then
        _fail "01-colors.sh not found"
    else
        _pass "01-colors.sh exists"
    fi

    local worlds_file
    worlds_file=$(echo "$output" | sed -n '/=== 3WORLDS ===/,/=== TOOLS_DIR ===/p' | tail -n +2 | head -1)
    if [[ "$worlds_file" == "NO_3WORLDS" ]]; then
        _fail "3worlds.sh not found"
    else
        _pass "3worlds.sh exists"
    fi

    # Tools listing
    _info "Tools available:"
    echo "$output" | sed -n '/=== TOOLS_DIR ===/,/^$/p' | tail -n +2 | head -10 | while IFS= read -r line; do
        [[ -n "$line" ]] && c 252 "    $line"
        printf '\n'
    done
}

# ============================================================
# MODULE: SYNC — Syncthing connectivity
# ============================================================
mod_sync() {
    _hdr "SYNCTHING → MUMU"

    local st_port="${NODE_MUMU_ST_PORT:-8386}"
    local st_url="http://${MUMU_HOST}:${st_port}"
    local st_key="${NODE_MUMU_ST_KEY:-}"

    # Test 1: Syncthing GUI reachable
    if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$st_url/rest/noauth/health" 2>/dev/null | grep -q "200"; then
        _pass "Syncthing GUI reachable: $st_url"
    else
        _warn "Syncthing GUI not reachable at $st_url"
        _info "Check if Syncthing is running on mumu"
    fi

    # Test 2: API key
    if [[ -n "$st_key" ]]; then
        _pass "Syncthing API key configured"
    else
        _warn "Syncthing API key not set"
    fi

    # Test 3: System status via API
    if [[ -n "$st_key" ]]; then
        local status
        status=$(curl -s -H "X-API-Key: $st_key" --max-time 5 "$st_url/rest/system/status" 2>/dev/null)
        if [[ -n "$status" ]]; then
            local version
            version=$(echo "$status" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
            if [[ -n "$version" ]]; then
                _pass "Syncthing version: $version"
            fi
        fi
    fi
}

# ============================================================
# MODULE: FIX — Auto-fix common issues
# ============================================================
fix_micro() {
    _hdr "FIX: MICRO EDITOR"

    local ssh_opts=(-p "$MUMU_PORT" -o ConnectTimeout=8 -o BatchMode=yes)
    [[ -f "$MUMU_KEY" ]] && ssh_opts+=(-i "$MUMU_KEY")

    local fix_cmd='
        FIXED=0

        # Fix 1: Install micro if missing
        if ! command -v micro &>/dev/null; then
            echo "Installing micro..."
            if command -v pkg &>/dev/null; then
                pkg install -y micro
                FIXED=1
            elif command -v apt &>/dev/null; then
                apt install -y micro
                FIXED=1
            fi
        fi

        # Fix 2: Create config dir if missing
        if [[ ! -d ~/.config/micro ]]; then
            mkdir -p ~/.config/micro
            echo "Created ~/.config/micro/"
            FIXED=1
        fi

        # Fix 3: Remove corrupted settings
        if [[ -f ~/.config/micro/settings.json ]]; then
            if ! python3 -c "import json; json.load(open(\"$HOME/.config/micro/settings.json\"))" 2>/dev/null; then
                rm ~/.config/micro/settings.json
                echo "Removed corrupted settings.json"
                FIXED=1
            fi
        fi

        # Fix 4: Clear broken plugin cache
        if [[ -d ~/.config/micro/lists ]]; then
            rm -rf ~/.config/micro/lists/
            echo "Cleared micro lists cache"
            FIXED=1
        fi

        if [[ $FIXED -eq 1 ]]; then
            echo "FIXES_APPLIED"
        else
            echo "NO_FIXES_NEEDED"
        fi
    '

    local output
    output=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" "$fix_cmd" 2>/dev/null)

    echo "$output" | while IFS= read -r line; do
        case "$line" in
            FIXES_APPLIED)  _fix "Micro fixes applied" ;;
            NO_FIXES_NEEDED) _pass "No micro fixes needed" ;;
            *"Created"*)    _fix "$line" ;;
            *"Removed"*)    _fix "$line" ;;
            *"Cleared"*)    _fix "$line" ;;
            *"Installing"*) _fix "$line" ;;
            *) [[ -n "$line" ]] && _info "$line" ;;
        esac
    done
}

fix_zsh() {
    _hdr "FIX: ZSH SHELL"

    local ssh_opts=(-p "$MUMU_PORT" -o ConnectTimeout=8 -o BatchMode=yes)
    [[ -f "$MUMU_KEY" ]] && ssh_opts+=(-i "$MUMU_KEY")

    local fix_cmd='
        FIXED=0

        # Fix 1: Install zsh if missing
        if ! command -v zsh &>/dev/null; then
            echo "Installing zsh..."
            if command -v pkg &>/dev/null; then
                pkg install -y zsh
                FIXED=1
            fi
        fi

        # Fix 2: Create .zshrc from template if missing
        if [[ ! -f ~/.zshrc ]]; then
            if [[ -f ~/bashscripts/profiles/termux/.zshrc ]]; then
                cp ~/bashscripts/profiles/termux/.zshrc ~/.zshrc
                echo "Copied .zshrc from bashscripts/profiles/termux/"
                FIXED=1
            fi
        fi

        # Fix 3: Install Oh My Zsh if missing
        if [[ ! -d ~/.oh-my-zsh ]]; then
            echo "Installing Oh My Zsh..."
            RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>/dev/null
            FIXED=1
        fi

        # Fix 4: Install powerlevel10k if missing
        if [[ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]]; then
            echo "Installing powerlevel10k..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
                ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 2>/dev/null
            FIXED=1
        fi

        # Fix 5: Install missing plugins
        for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
            local plug_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
            if [[ ! -d "$plug_dir" ]]; then
                echo "Installing $plugin..."
                local repo="zsh-users/$plugin"
                git clone --depth=1 "https://github.com/$repo.git" "$plug_dir" 2>/dev/null
                FIXED=1
            fi
        done

        # Fix 6: Set default shell
        if [[ "$SHELL" != *"zsh"* ]]; then
            echo "Setting zsh as default shell..."
            chsh -s zsh 2>/dev/null || echo "Run: chsh -s \$(which zsh)"
            FIXED=1
        fi

        if [[ $FIXED -eq 1 ]]; then
            echo "FIXES_APPLIED"
        else
            echo "NO_FIXES_NEEDED"
        fi
    '

    local output
    output=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" "$fix_cmd" 2>/dev/null)

    echo "$output" | while IFS= read -r line; do
        case "$line" in
            FIXES_APPLIED)  _fix "Zsh fixes applied" ;;
            NO_FIXES_NEEDED) _pass "No zsh fixes needed" ;;
            *"Installing"*) _fix "$line" ;;
            *"Copied"*)     _fix "$line" ;;
            *"Setting"*)    _fix "$line" ;;
            *) [[ -n "$line" ]] && _info "$line" ;;
        esac
    done
}

fix_joe() {
    _hdr "FIX: JOE SCRIPTS"

    local ssh_opts=(-p "$MUMU_PORT" -o ConnectTimeout=8 -o BatchMode=yes)
    [[ -f "$MUMU_KEY" ]] && ssh_opts+=(-i "$MUMU_KEY")

    local fix_cmd='
        FIXED=0

        # Check if bashscripts exists
        if [[ ! -d ~/bashscripts ]]; then
            echo "bashscripts directory not found"
            echo "Please sync via Syncthing or git clone"
            exit 1
        fi

        # Fix 1: Ensure JOE_ENV is set in rc files
        for rc in ~/.bashrc ~/.zshrc; do
            if [[ -f "$rc" ]] && ! grep -q "JOE_ENV" "$rc"; then
                echo "" >> "$rc"
                echo "# Joe Environment" >> "$rc"
                if uname -r | grep -q "microsoft"; then
                    echo "export JOE_ENV=WSL" >> "$rc"
                elif [[ -d "/data/data/com.termux" ]]; then
                    echo "export JOE_ENV=TERMUX" >> "$rc"
                fi
                echo "Added JOE_ENV to $rc"
                FIXED=1
            fi
        done

        # Fix 2: Ensure joe.sh is sourced
        for rc in ~/.bashrc ~/.zshrc; do
            if [[ -f "$rc" ]] && ! grep -q "joe.sh" "$rc"; then
                echo "" >> "$rc"
                echo "# Load Joe Scripts" >> "$rc"
                echo "source ~/bashscripts/joe.sh 2>/dev/null" >> "$rc"
                echo "Added joe.sh source to $rc"
                FIXED=1
            fi
        done

        if [[ $FIXED -eq 1 ]]; then
            echo "FIXES_APPLIED"
        else
            echo "NO_FIXES_NEEDED"
        fi
    '

    local output
    output=$(ssh "${ssh_opts[@]}" "$MUMU_USER@$MUMU_HOST" "$fix_cmd" 2>/dev/null)

    echo "$output" | while IFS= read -r line; do
        case "$line" in
            FIXES_APPLIED)  _fix "Joe scripts fixes applied" ;;
            NO_FIXES_NEEDED) _pass "No joe scripts fixes needed" ;;
            *"Added"*)      _fix "$line" ;;
            *"not found"*)  _warn "$line" ;;
            *) [[ -n "$line" ]] && _info "$line" ;;
        esac
    done
}

# ============================================================
# MAIN
# ============================================================
main() {
    local mode="${1:-all}"
    local fix_mode=0

    # Parse flags
    if [[ "$1" == "--fix" ]]; then
        fix_mode=1
        mode="${2:-all}"
    fi

    cn 45 "╔═══════════════════════════════════════════════╗"
    cn 226 "║  MUMU ENVIRONMENT DEBUGGER                   ║"
    cn 45 "║  Target: $MUMU_USER@$MUMU_HOST:$MUMU_PORT"
    cn 45 "╚═══════════════════════════════════════════════╝"

    case "$mode" in
        env)
            mod_env
            ;;
        ssh)
            mod_ssh
            ;;
        micro)
            mod_micro
            if (( fix_mode )); then fix_micro; fi
            ;;
        zsh)
            mod_zsh
            if (( fix_mode )); then fix_zsh; fi
            ;;
        joe)
            mod_joe
            if (( fix_mode )); then fix_joe; fi
            ;;
        sync)
            mod_sync
            ;;
        all)
            mod_env
            mod_ssh
            if (( $? == 0 )); then
                mod_micro
                mod_zsh
                mod_joe
                mod_sync
            fi
            if (( fix_mode )); then
                cn 226 "\n═══ AUTO-FIX MODE ═══"
                fix_micro
                fix_zsh
                fix_joe
            fi
            ;;
        --help|-h)
            echo "Usage: mumu-debug.sh [all|env|ssh|micro|zsh|joe|sync]"
            echo "       mumu-debug.sh --fix [micro|zsh|joe|all]"
            echo ""
            echo "Modules:"
            echo "  env   - Local environment validation"
            echo "  ssh   - SSH connectivity to MUMU"
            echo "  micro - Micro editor diagnostics"
            echo "  zsh   - Zsh shell diagnostics"
            echo "  joe   - Joe scripts validation"
            echo "  sync  - Syncthing connectivity"
            echo "  all   - Run all modules (default)"
            echo ""
            echo "Flags:"
            echo "  --fix - Auto-fix common issues"
            echo "  --help|-h - Show this help"
            exit 0
            ;;
        *)
            cn 196 "Unknown module: $mode"
            cn 252 "Usage: mumu-debug.sh [all|env|ssh|micro|zsh|joe|sync]"
            exit 1
            ;;
    esac

    summary
}

main "$@"
