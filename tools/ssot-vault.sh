#!/usr/bin/env bash
# ============================================================
# 🔐 SSOT Secret Vault Manager (AES-256 PBKDF2)
# ============================================================
# File: tools/ssot-vault.sh
# Purpose: Zero-dependency, military-grade credential vault
#          for syncing secret .env across multi-device SSOT
# Target: $SSOT/core/.env.enc <---> $HOME/.env ($SSOT/.env)
# ============================================================

set -eo pipefail 2>/dev/null || true

# ── 1. SSOT Root & Environment Resolution ──
_SSOT_ROOT="${SSOT:-$HOME/bashscripts}"
if [[ ! -d "$_SSOT_ROOT" ]]; then
    _SSOT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
export SSOT="$_SSOT_ROOT"

# ── 2. Load Color Engine ──
if [[ -f "$SSOT/core/01-colors.sh" ]]; then
    source "$SSOT/core/01-colors.sh"
fi

if ! declare -f cn >/dev/null 2>&1; then
    cn() {
        local col="${1:-}" style="${2:-}"
        shift 2 2>/dev/null || shift $#
        echo "$*"
    }
    c() {
        local col="${1:-}" style="${2:-}"
        shift 2 2>/dev/null || shift $#
        printf "%s" "$*"
    }
fi

# ── 3. Paths & Configurations ──
VAULT_FILE="$SSOT/core/.env.enc"
EXAMPLE_FILE="$SSOT/.env.example"
LOCAL_ENV="$HOME/.env"
SSOT_ENV="$SSOT/.env"
PBKDF2_ITER=100000

# ── 4. Helper Functions ──
_banner() {
    echo ""
    c 39 b "╔══════════════════════════════════════════════════════════╗" && echo ""
    c 39 b "║   🔐  SSOT Secret Vault (AES-256-CBC PBKDF2)           ║" && echo ""
    c 39 b "╚══════════════════════════════════════════════════════════╝" && echo ""
    echo ""
}

_resolve_active_env() {
    if [[ -f "$LOCAL_ENV" ]]; then
        echo "$LOCAL_ENV"
    elif [[ -f "$SSOT_ENV" ]]; then
        echo "$SSOT_ENV"
    else
        echo ""
    fi
}

_ensure_openssl() {
    if ! command -v openssl >/dev/null 2>&1; then
        cn 196 b "❌ Error: 'openssl' is not installed."
        echo "Please install openssl via your package manager (pkg install openssl / apt install openssl)."
        exit 1
    fi
}

# ── 5. Core Commands ──

# --- LOCK / ENCRYPT ---
cmd_lock() {
    _banner
    _ensure_openssl

    local target_env="$(_resolve_active_env)"
    if [[ -z "$target_env" ]]; then
        cn 196 b "❌ Error: No .env file found at $LOCAL_ENV or $SSOT_ENV"
        echo "Create your .env first or copy from $EXAMPLE_FILE"
        exit 1
    fi

    cn 226 b "🔒 Locking secrets from: $target_env"
    mkdir -p "$(dirname "$VAULT_FILE")"

    # Prompt for passphrase
    local pass1 pass2
    if [[ -n "${SSOT_VAULT_PASS:-}" ]]; then
        pass1="$SSOT_VAULT_PASS"
    else
        read -r -s -p "Enter Master Vault Passphrase: " pass1
        echo ""
        if [[ -z "$pass1" ]]; then
            cn 196 b "❌ Passphrase cannot be empty."
            exit 1
        fi

        read -r -s -p "Confirm Master Vault Passphrase: " pass2
        echo ""
        if [[ "$pass1" != "$pass2" ]]; then
            cn 196 b "❌ Passphrases do not match!"
            exit 1
        fi
    fi

    # Encrypt
    if echo "$pass1" | openssl enc -aes-256-cbc -pbkdf2 -iter "$PBKDF2_ITER" -salt -in "$target_env" -out "$VAULT_FILE" -pass stdin 2>/dev/null; then
        chmod 644 "$VAULT_FILE"
        echo ""
        cn 82 b "  ✅ Vault locked successfully!"
        echo "  📦 Output: $VAULT_FILE ($(wc -c < "$VAULT_FILE" | tr -d ' ') bytes)"
        echo ""
        cn 214 b "💡 Next steps:"
        echo "   git -C "$SSOT" add "$VAULT_FILE""
        echo "   git -C "$SSOT" commit -m "chore: update encrypted secrets vault""
        echo "   git -C "$SSOT" push"
        echo ""
    else
        cn 196 b "❌ Failed to encrypt vault."
        exit 1
    fi
}

# --- UNLOCK / DECRYPT ---
cmd_unlock() {
    _banner
    _ensure_openssl

    if [[ ! -f "$VAULT_FILE" ]]; then
        cn 196 b "❌ Error: Vault file not found: $VAULT_FILE"
        echo "Ensure the repository is cloned and $VAULT_FILE exists."
        exit 1
    fi

    cn 226 b "🔓 Unlocking secrets from: $VAULT_FILE"
    local pass
    if [[ -n "${SSOT_VAULT_PASS:-}" ]]; then
        pass="$SSOT_VAULT_PASS"
    else
        read -r -s -p "Enter Master Vault Passphrase: " pass
        echo ""
    fi

    if [[ -z "$pass" ]]; then
        cn 196 b "❌ Passphrase cannot be empty."
        exit 1
    fi

    local tmp_out
    tmp_out="$(mktemp)"

    if echo "$pass" | openssl enc -d -aes-256-cbc -pbkdf2 -iter "$PBKDF2_ITER" -in "$VAULT_FILE" -out "$tmp_out" -pass stdin 2>/dev/null; then
        if [[ ! -s "$tmp_out" ]]; then
            rm -f "$tmp_out"
            cn 196 b "❌ Decryption resulted in empty content. Wrong passphrase?"
            exit 1
        fi

        mv "$tmp_out" "$LOCAL_ENV"
        chmod 600 "$LOCAL_ENV"
        ln -sf "$LOCAL_ENV" "$SSOT_ENV"

        echo ""
        cn 82 b "  ✅ Vault decrypted successfully!"
        echo "  📄 Secrets written to: $LOCAL_ENV (chmod 600)"
        echo "  🔗 Symlinked: $SSOT_ENV -> $LOCAL_ENV"
        echo ""
    else
        rm -f "$tmp_out"
        echo ""
        cn 196 b "❌ Decryption failed. Incorrect passphrase or corrupted vault file!"
        exit 1
    fi
}

# --- AUDIT ---
cmd_audit() {
    _banner
    local active_env="$(_resolve_active_env)"

    if [[ ! -f "$EXAMPLE_FILE" ]]; then
        cn 196 b "❌ Error: Example template missing: $EXAMPLE_FILE"
        exit 1
    fi

    echo "📋 Comparing Active Secrets with Template:"
    echo "   Template : $EXAMPLE_FILE"
    if [[ -n "$active_env" ]]; then
        echo "   Active   : $active_env"
    else
        cn 196 b "   Active   : NOT FOUND (Run 'ssot-vault unlock' first!)"
        echo ""
        return 1
    fi
    echo ""

    printf " %-30s | %-12s | %s\n" "VARIABLE NAME" "STATUS" "VALUE PREVIEW"
    printf "%s\n" "────────────────────────────────────────────────────────────────────────"

    local total=0 ok_count=0 empty_count=0 missing_count=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            local var_name="${BASH_REMATCH[2]}"
            total=$((total+1))

            if grep -q "^[[:space:]]*\(export[[:space:]]\+\)\?${var_name}=" "$active_env" 2>/dev/null; then
                local raw_val
                raw_val="$(grep -m 1 "^[[:space:]]*\(export[[:space:]]\+\)\?${var_name}=" "$active_env" | sed -E 's/^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=//' | tr -d '"' | tr -d "'")"
                if [[ -n "$raw_val" ]]; then
                    ok_count=$((ok_count+1))
                    local masked
                    if (( ${#raw_val} > 8 )); then
                        masked="${raw_val:0:3}..."
                    else
                        masked="***"
                    fi
                    printf " %-30s | %s | %s\n" "$var_name" "$(c 82 b "SET 🟢")" "$masked"
                else
                    empty_count=$((empty_count+1))
                    printf " %-30s | %s | %s\n" "$var_name" "$(c 226 b "EMPTY 🟡")" "(empty string)"
                fi
            else
                missing_count=$((missing_count+1))
                printf " %-30s | %s | %s\n" "$var_name" "$(c 196 b "MISSING 🔴")" "Not in .env"
            fi
        fi
    done < "$EXAMPLE_FILE"

    echo ""
    printf " Summary: Total: %d | OK: %s | Empty: %s | Missing: %s\n" \
        "$total" \
        "$(c 82 b "$ok_count")" \
        "$(c 226 b "$empty_count")" \
        "$(c 196 b "$missing_count")"
    echo ""
}

# --- STATUS ---
cmd_status() {
    _banner
    echo "📊 SSOT Vault Status:"
    echo ""
    if [[ -f "$VAULT_FILE" ]]; then
        local v_size v_time
        v_size="$(wc -c < "$VAULT_FILE" | tr -d ' ')"
        v_time="$(date -r "$VAULT_FILE" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || stat -c "%y" "$VAULT_FILE" 2>/dev/null || echo "present")"
        echo "  📦 Encrypted Vault : $(c 82 b "EXISTS") ($VAULT_FILE)"
        echo "     Size            : ${v_size} bytes"
        echo "     Last Modified   : ${v_time}"
    else
        echo "  📦 Encrypted Vault : $(c 196 b "NOT FOUND") ($VAULT_FILE)"
    fi

    local active_env="$(_resolve_active_env)"
    if [[ -n "$active_env" ]]; then
        local e_size e_time
        e_size="$(wc -c < "$active_env" | tr -d ' ')"
        e_time="$(date -r "$active_env" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || stat -c "%y" "$active_env" 2>/dev/null || echo "present")"
        echo "  📄 Active .env     : $(c 82 b "EXISTS") ($active_env)"
        echo "     Size            : ${e_size} bytes"
        echo "     Last Modified   : ${e_time}"
    else
        echo "  📄 Active .env     : $(c 226 b "NOT FOUND")"
    fi

    if [[ -L "$SSOT_ENV" ]]; then
        echo "  🔗 SSOT Symlink    : $(c 82 b "HEALTHY") ($SSOT_ENV -> $(readlink "$SSOT_ENV"))"
    elif [[ -f "$SSOT_ENV" ]]; then
        echo "  🔗 SSOT Symlink    : $(c 226 b "REGULAR FILE") (Consider symlinking to ~/.env)"
    else
        echo "  🔗 SSOT Symlink    : $(c 246 b "NONE")"
    fi
    echo ""
}

# ── 6. CLI Dispatcher ──
case "${1:-}" in
    lock|encrypt)
        cmd_lock
        ;;
    unlock|decrypt)
        cmd_unlock
        ;;
    audit|check)
        cmd_audit
        ;;
    status)
        cmd_status
        ;;
    *)
        _banner
        echo "Usage: $(basename "$0") <command>"
        echo ""
        echo "Commands:"
        echo "  lock    (encrypt)  Encrypt active ~/.env into $VAULT_FILE"
        echo "  unlock  (decrypt)  Decrypt $VAULT_FILE into ~/.env"
        echo "  audit   (check)    Audit active .env against .env.example"
        echo "  status             Check status of vault and local credentials"
        echo ""
        exit 0
        ;;
esac
