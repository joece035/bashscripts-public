#!/bin/bash
# ============================================================
# syncctl/lib/api.sh — Syncthing REST API client
# ============================================================
# Single entry point: api_call <method> <path> [data]
# Returns: JSON string on stdout, "" on error (and SYNCCTL_API_ERR set)
#
# Uses curl. Override `api_call` in mock.sh for testing.
# ============================================================

# No top-level guard — helper functions (get_folder_config, etc.) must
# always be available. api_call uses a function-existence guard below so
# mock.sh can override it without being clobbered on re-source.

# Ensure deps
_syncctl_require_curl() {
    command -v curl >/dev/null 2>&1 || {
        echo "syncctl: curl is required" >&2
        return 1
    }
}

# ──────────────────────────────────────────────────────────
# api_call <method> <base_url> <api_key> <path> [data]
#   method: GET | POST | PUT | DELETE | PATCH
#   base_url: e.g. http://termux:8384
#   api_key:  Syncthing API key (X-API-Key header)
#   path:     e.g. /rest/system/status
#   data:     optional JSON body for POST/PUT
# Returns: 0 on success (HTTP 2xx), 1 on failure
# Sets globals:
#   SYNCCTL_API_ERR      - error message (empty if success)
#   SYNCCTL_API_HTTP     - HTTP code (e.g. 200, 401, 000)
#   SYNCCTL_API_BODY     - response body
#
# OVERRIDDEN by mock.sh in test mode.
# ──────────────────────────────────────────────────────────
# Function-existence guard: only define api_call if not already defined.
# This lets mock.sh define it first (when sourced in test mode), and
# subsequent sources of api.sh will NOT override the mock.
if ! declare -F api_call >/dev/null 2>&1; then
api_call() {
    local method="$1" base_url="$2" api_key="$3" path="$4" data="${5:-}"
    _syncctl_require_curl || return 1

    SYNCCTL_API_ERR=""
    SYNCCTL_API_HTTP="000"
    SYNCCTL_API_BODY=""

    # Sanity
    [[ -z "$base_url" ]] && { SYNCCTL_API_ERR="empty base_url"; return 1; }
    [[ -z "$path" || "$path" != /* ]] && { SYNCCTL_API_ERR="path must start with /"; return 1; }

    local url="${base_url%/}${path}"
    local tmp_body tmp_err
    tmp_body="$(mktemp)" || { SYNCCTL_API_ERR="mktemp failed"; return 1; }
    tmp_err="$(mktemp)"  || { rm -f "$tmp_body"; SYNCCTL_API_ERR="mktemp failed"; return 1; }
    trap "rm -f '$tmp_body' '$tmp_err'" RETURN

    local args=(
        --silent --show-error
        --max-time "$SYNCCTL_API_TIMEOUT"
        -X "$method"
        -H "X-API-Key: ${api_key}"
        -H "Accept: application/json"
        -o "$tmp_body"
        -w "%{http_code}"
    )
    [[ -n "$data" ]] && args+=( -H "Content-Type: application/json" --data-raw "$data" )
    args+=( "$url" )

    local http
    if ! http="$(curl "${args[@]}" 2>"$tmp_err")"; then
        SYNCCTL_API_ERR="$(cat "$tmp_err" 2>/dev/null | head -1)"
        SYNCCTL_API_ERR="${SYNCCTL_API_ERR:-curl failed}"
        return 1
    fi

    SYNCCTL_API_HTTP="$http"
    SYNCCTL_API_BODY="$(cat "$tmp_body" 2>/dev/null)"

    # Treat 2xx as success
    if [[ "$http" =~ ^2 ]]; then
        return 0
    fi
    SYNCCTL_API_ERR="HTTP $http: $(echo "$SYNCCTL_API_BODY" | head -c 200)"
    return 1
}
fi  # end api_call guard

# ──────────────────────────────────────────────────────────
# Helpers below — ALWAYS defined (not protected by guard)
# Override api_call above to mock; helpers will use the mock.
# ──────────────────────────────────────────────────────────

# api_device <device_name> <method> <path> [data]
# Looks up URL/key from SYNCCTL_API_URLS / SYNCCTL_API_KEYS
api_device() {
    local dev="$1" method="$2" path="$3" data="${4:-}"
    local url key
    url="$(syncctl_get_api_url "$dev")"
    key="$(syncctl_get_api_key "$dev")"
    [[ -z "$url" ]] && { SYNCCTL_API_ERR="no API URL for device '$dev'"; return 1; }
    [[ -z "$key" ]] && { SYNCCTL_API_ERR="no API key for device '$dev'"; return 1; }
    api_call "$method" "$url" "$key" "$path" "$data"
}

# api_self <method> <path> [data]  — call local Syncthing
api_self() {
    [[ -z "$SYNCCTL_LOCAL_API_URL" ]] && { SYNCCTL_API_ERR="no local API URL (JOE_ENV=$JOE_ENV)"; return 1; }
    [[ -z "$SYNCCTL_LOCAL_API_KEY" ]] && { SYNCCTL_API_ERR="no local API key"; return 1; }
    api_call "$1" "$SYNCCTL_LOCAL_API_URL" "$SYNCCTL_LOCAL_API_KEY" "$2" "${3:-}"
}

# ──────────────────────────────────────────────────────────
# Domain helpers
# ──────────────────────────────────────────────────────────

# get_folder_config <device>  → echoes JSON or sets SYNCCTL_API_ERR
get_folder_config() {
    api_device "$1" GET "/rest/config/folders/$SYNCCTL_FOLDER_ID"
}

# set_folder_type <device> <sendonly|receiveonly>
set_folder_type() {
    local dev="$1" new_type="$2"
    case "$new_type" in
        sendonly|receiveonly|sendreceive) ;;
        *) SYNCCTL_API_ERR="invalid folder type: $new_type"; return 1 ;;
    esac
    local data
    data="$(printf '{"type":"%s"}' "$new_type")"
    api_device "$dev" PATCH "/rest/config/folders/$SYNCCTL_FOLDER_ID" "$data"
}

# get_folder_errors <device>  → echoes JSON
get_folder_errors() {
    api_device "$1" GET "/rest/folder/errors?id=$SYNCCTL_FOLDER_ID"
}

# get_completion <device>  → echoes JSON (needCompletion)
# 100 = in sync, < 100 = still syncing
get_completion() {
    api_device "$1" GET "/rest/db/completion?folder=$SYNCCTL_FOLDER_ID"
}

# get_system_status <device>  → echoes JSON
get_system_status() {
    api_device "$1" GET "/rest/system/status"
}

# get_system_version <device>  → echoes JSON
get_system_version() {
    api_device "$1" GET "/rest/system/version"
}
