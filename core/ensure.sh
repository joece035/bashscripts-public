#!/bin/bash

# ==============================================================================
# Helper: ensure <cmd> [package_name]
# ------------------------------------------------------------------------------
# ตรวจสอบว่ามีคำสั่ง <cmd> ในระบบหรือไม่ หากไม่มีจะติดตั้งแพ็กเกจให้อัตโนมัติ
# รองรับทั้ง Termux (pkg) และ WSL/Linux (apt) ตาม SSOT JOE_ENV
# ==============================================================================

ensure_() {
    local cmd="${1:-}"
    local pkg="${2:-$cmd}"

    # --------------------------------------------------------------------------
    # 0. Validate
    # --------------------------------------------------------------------------
    [[ -z "$cmd" ]] && {
        cn 196 bi "❌ ensure: missing command name" >&2
        return 2
    }

    # --------------------------------------------------------------------------
    # 1. Already available
    # --------------------------------------------------------------------------
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi

    # --------------------------------------------------------------------------
    # 2. External / Windows command
    # --------------------------------------------------------------------------
    # Linux/Termux ไม่ควรพยายามติดตั้ง .exe ผ่าน pkg/apt
    if [[ "$cmd" == *.exe ]]; then
        cn 220 bi "⚠️ External command '$cmd' not found" >&2
        return 1
    fi

    cn 220 bi "⚠️ '$cmd' not found → installing '$pkg'..." >&2

    # --------------------------------------------------------------------------
    # 3. Termux
    # --------------------------------------------------------------------------
    if command -v pkg >/dev/null 2>&1; then

        if ! pkg install -y "$pkg"; then
            cn 196 bi "❌ Failed to install '$pkg' via pkg" >&2
            return 1
        fi

    # --------------------------------------------------------------------------
    # 4. Debian / Ubuntu / WSL
    # --------------------------------------------------------------------------
    elif command -v apt-get >/dev/null 2>&1; then

        local apt_cmd=(apt-get)

        if (( EUID != 0 )); then
            if ! command -v sudo >/dev/null 2>&1; then
                cn 196 bi "❌ sudo is required but not installed" >&2
                return 1
            fi

            apt_cmd=(sudo apt-get)
        fi

        # update only once per shell session
        if [[ -z "${JOE_APT_UPDATED:-}" ]]; then
            if ! "${apt_cmd[@]}" update -qq; then
                cn 196 bi "❌ apt update failed" >&2
                return 1
            fi

            export JOE_APT_UPDATED=1
        fi

        if ! "${apt_cmd[@]}" install -y "$pkg"; then
            cn 196 bi "❌ Failed to install '$pkg' via apt" >&2
            return 1
        fi

    # --------------------------------------------------------------------------
    # 5. Unsupported environment
    # --------------------------------------------------------------------------
    else
        cn 196 bi "❌ No supported package manager found for '$cmd'" >&2
        return 1
    fi

    # --------------------------------------------------------------------------
    # 6. Verify
    # --------------------------------------------------------------------------
    if command -v "$cmd" >/dev/null 2>&1; then
        cn 10 bi "✅ '$cmd' is ready" >&2
        return 0
    fi

    cn 196 bi "❌ '$pkg' installed, but '$cmd' is still unavailable" >&2
    return 1
}