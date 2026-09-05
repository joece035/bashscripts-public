#!/bin/bash

#
# Or clone first, then run:

#
# Idempotent: safe to re-run. Skips completed steps.
# ============================================================

# -- command line to install SSOT
pkg_helper() {
    if [ "$#" -eq 0 ]; then
        echo "❌ Usage: pkg_helper <package_1> [package_2 ...]" >&2
        return 1
    fi

    if command -v pkg >/dev/null 2>&1; then
        pkg update -y && pkg install -y "$@"
    elif command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
        local sudo_cmd=""
        if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
            sudo_cmd="sudo"
        fi
        DEBIAN_FRONTEND=noninteractive $sudo_cmd apt-get update -qq && \
        DEBIAN_FRONTEND=noninteractive $sudo_cmd apt-get install -y -qq "$@"
    elif command -v apk >/dev/null 2>&1; then
        apk update && apk add --no-cache "$@"
    elif command -v pacman >/dev/null 2>&1; then
        local sudo_cmd=""
        [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && sudo_cmd="sudo"
        $sudo_cmd pacman -Sy --noconfirm "$@"
    else
        echo "❌ Error: No supported package manager found" >&2
        return 1
    fi
}
pkg_helper curl git
curl -fsSL https://raw.githubusercontent.com/joece035/bashscripts-public/main/bootstrap/install.sh | bash

# -- or 

git clone https://github.com/joece035/bashscripts-public.git ~/bashscripts
bash ~/bashscripts/bootstrap/install.sh




