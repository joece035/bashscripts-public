# ZSH MANAGER - Termux-specific functions
# All IPs/Users come from .bashjoe (no hardcoding here)

recon() {
    [ -z "$TERMUX_IP" ] && echo "TERMUX_IP not set in .bashjoe" && return 1
    adb connect "${TERMUX_IP}:5555" 2>/dev/null
    echo "ADB connected to ${TERMUX_IP}"
}

hmgw() {
    pkill -f "hermes gateway" 2>/dev/null
    pkill -f "hermes dashboard" 2>/dev/null
    sleep 1
    mkdir -p ~/.hermes/logs
    hermes gateway >/dev/null 2>&1 &
    hermes dashboard >/dev/null 2>&1 &
    echo "Hermes started in background"
}

opdb() {
    local dash_path="${dbp:-$HOME/dashboard}"
    local venv_python="$dash_path/.venv/bin/python"
    if [ ! -d "$dash_path" ]; then echo "Not found: $dash_path"; return 1; fi
    echo "Launching Dashboard..."
    cd "$dash_path"
    if [ -f "$venv_python" ]; then "$venv_python" server.py &; else python3 server.py &; fi
    echo "Dashboard started http://localhost:5050"
}

tsc() {
    local base_path="${dbp:-$HOME/dashboard}"
    local venv_python="$base_path/.venv/bin/python"
    local script_path="api/engines/trend_scan/daily_trend_scan.py"
    if [ ! -f "$base_path/$script_path" ]; then echo "Not found: $base_path/$script_path"; return 1; fi
    echo "Starting Trend Scan..."
    cd "$base_path"
    "$venv_python" "$script_path"
    cd - >/dev/null
    echo "Trend Scan done"
}
