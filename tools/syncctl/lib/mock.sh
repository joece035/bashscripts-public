#!/bin/bash
# ============================================================
# syncctl/lib/mock.sh — Mock Syncthing API for testing
# ============================================================
# Overrides api_call & folder type setters for test fixtures.
# NO guard line here so re-sourcing in tests always installs mock.
# ============================================================

source "$(dirname "${BASH_SOURCE[0]}")/api.sh"

declare -gA MOCK_FOLDER_TYPES=()

set_folder_type() {
    local dev="$1" type="$2"
    MOCK_FOLDER_TYPES["$dev"]="$type"
    SYNCCTL_API_HTTP="200"
    SYNCCTL_API_BODY="{\"type\":\"$type\"}"
    audit_log "ownership" "action=set_type" "device=$dev" "type=$type"
    return 0
}

get_folder_type() {
    local dev="$1"
    if [[ -n "${MOCK_FOLDER_TYPES[$dev]:-}" ]]; then
        echo "${MOCK_FOLDER_TYPES[$dev]}"
        return 0
    fi
    local m
    m="$(state_get_local_master 2>/dev/null)"
    if [[ -n "$m" && "$dev" == "$m" ]]; then
        echo "sendonly"
    else
        echo "receiveonly"
    fi
}

get_folder_config() {
    local dev="$1"
    local t
    t="$(get_folder_type "$dev")"
    SYNCCTL_API_HTTP="200"
    SYNCCTL_API_BODY="{\"id\":\"$SYNCCTL_FOLDER_ID\",\"type\":\"$t\"}"
    return 0
}

get_completion() {
    local dev="$1"
    SYNCCTL_API_HTTP="200"
    SYNCCTL_API_BODY='{"completion":100}'
    return 0
}

get_folder_errors() {
    local dev="$1"
    SYNCCTL_API_HTTP="200"
    SYNCCTL_API_BODY='{}'
    return 0
}

get_system_version() {
    local dev="$1"
    SYNCCTL_API_HTTP="200"
    SYNCCTL_API_BODY='{"version":"v1.23.0"}'
    return 0
}

api_call() {
    local method="$1" base_url="$2" api_key="$3" path="$4" data="${5:-}"
    SYNCCTL_API_ERR="" SYNCCTL_API_HTTP="200" SYNCCTL_API_BODY=""
    if [[ "$path" == *"/rest/db/completion"* ]]; then
        SYNCCTL_API_BODY='{"completion":100}'
    elif [[ "$path" == *"/rest/system/version"* ]]; then
        SYNCCTL_API_BODY='{"version":"v1.23.0"}'
    elif [[ "$path" == *"/rest/folder/errors"* ]]; then
        SYNCCTL_API_BODY='{}'
    else
        SYNCCTL_API_BODY='{"type":"sendonly"}'
    fi
    return 0
}
