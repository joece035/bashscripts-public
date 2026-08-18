#!/usr/bin/env bash
# ============================================================
# install-syncthing-service.sh — Install Syncthing as a Windows
# scheduled task that starts at boot (before any user login).
#
# Why:  Git-Bash nohup/disown fork gets killed when bash exits
#       (MSYS process group cleanup). schtasks /sc onstart /
#       ru SYSTEM survives logout, reboot, and is independent
#       of any shell session.
#
# Run ONCE per machine (after syncthing is installed via winget
# and config.xml already exists at %LOCALAPPDATA%\Syncthing\).
#
# Usage:  bash tools/install-syncthing-service.sh
# Remove: schtasks /delete /tn "Syncthing" /f
# ============================================================

set -euo pipefail

# SSOT paths — sync with 00-env.sh so we don't hardcode
# SYNCTHING_BIN_WIN  = Windows path (used in task XML — SYSTEM context can't parse MSYS paths)
# SYNCTHING_BIN      = MSYS / Git-Bash path (used for bash existence check)
SYNCTHING_BIN_WIN='C:\Users\User\AppData\Local\Microsoft\WinGet\Links\syncthing.exe'
SYNCTHING_BIN="/c/Users/User/AppData/Local/Microsoft/WinGet/Links/syncthing.exe"
TASK_NAME="Syncthing"
GUI_PORT="${NODE_WIN_ST_PORT:-8384}"

if [[ ! -f "$SYNCTHING_BIN" ]]; then
    echo "❌ syncthing.exe not found at: $SYNCTHING_BIN"
    echo "   Install with: winget install Syncthing.Syncthing"
    exit 1
fi

# Build the XML on the fly so we can:
#   - pin exact exe path
#   - pin GUI port
#   - run as SYSTEM (no user login needed)
#   - restart on failure
#   - UseHighestAvailable privileges
# Note: schtasks /xml is strict about element order. RunOnlyIfNetwork is
# omitted (default = true is fine for syncthing; it'll start before NIC).
read -r -d '' TASK_XML <<EOF || true
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Syncthing — file sync daemon (auto-start at boot, SYSTEM account, no login required)</Description>
    <Author>Joe</Author>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>5</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>${SYNCTHING_BIN_WIN}</Command>
      <Arguments>serve --gui-address=0.0.0.0:${GUI_PORT}</Arguments>
    </Exec>
  </Actions>
</Task>
EOF

# We need elevation to create a task. Self-elevate via Start-Process
# -Wait, then read the output.
TMP_XML="$(mktemp --suffix=.xml)"
# Write UTF-16 LE BOM (Task Scheduler is picky)
printf '\xff\xfe' > "$TMP_XML"
iconv -f UTF-8 -t UTF-16LE <<<"$TASK_XML" >> "$TMP_XML"

# Convert MSYS path -> Windows path for schtasks
WIN_XML=$(cygpath -w "$TMP_XML")

echo "▶ Installing scheduled task '$TASK_NAME' (SYSTEM, boot-trigger, port $GUI_PORT)…"

# Spawn elevated PowerShell — Relaunch as admin if needed.
powershell.exe -NoProfile -Command "
  \$xml = '$WIN_XML'
  # Delete any old instance first (clean re-install)
  schtasks /query /tn '$TASK_NAME' >\$null 2>&1
  if (\$LASTEXITCODE -eq 0) {
    Write-Host '  - existing task found, removing…'
    schtasks /delete /tn '$TASK_NAME' /f | Out-Null
  }
  schtasks /create /tn '$TASK_NAME' /xml \$xml | Out-Null
  if (\$LASTEXITCODE -ne 0) {
    Write-Host '❌ schtasks /create failed. Are you admin?'; exit 1
  }
  Write-Host '✅ Task created. Starting now for verification…'
  schtasks /run /tn '$TASK_NAME' | Out-Null
  Start-Sleep -Seconds 4
  \$alive = (Get-Process syncthing -ErrorAction SilentlyContinue | Measure-Object).Count
  Write-Host \"  - syncthing processes alive: \$alive\"
  if (\$alive -eq 0) {
    Write-Host '⚠️  Task started but syncthing not running. Check Event Viewer → Task Scheduler.'; exit 1
  }
  Write-Host '✅ Syncthing service is live.'
" || {
    echo "❌ PowerShell exited non-zero. Re-run from elevated PowerShell:"
    echo "   schtasks /create /tn \"$TASK_NAME\" /xml \"$WIN_XML\""
    rm -f "$TMP_XML"
    exit 1
}

rm -f "$TMP_XML"

echo ""
echo "✅ Done. Syncthing will auto-start on every boot (no user login needed)."
echo "   Useful commands:"
echo "     schtasks /run   /tn \"$TASK_NAME\"          # start now"
echo "     schtasks /end   /tn \"$TASK_NAME\"          # stop"
echo "     schtasks /query /tn \"$TASK_NAME\"          # status"
echo "     schtasks /delete /tn \"$TASK_NAME\" /f      # uninstall"