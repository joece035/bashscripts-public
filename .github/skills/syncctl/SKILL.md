---
name: syncctl
description: "Use when managing Syncthing cluster ownership, safe master handovers, or resolving .sync-conflict files. Trigger on: syncctl, syncthing master, transfer master, sync conflict, syncctl doctor."
---

# syncctl — Syncthing Ownership Controller

This skill guides the use of `syncctl`, a CLI tool that enforces a **Single Master** model for Syncthing folders across WSL, Windows, and Termux. It prevents write conflicts by ensuring only one device is `sendwhile` (Master) while others are `receiveonly` (Replica).

## Core Workflow

### 1. Health Check & Status
Before any operation, verify the current state of the cluster.
```bash
# Show current master, device list, and folder status
syncctl status

# Run a full 7-step audit (checks local state, cluster sync, conflicts, etc.)
syncctl doctor
```
**Decision:** If `doctor` reports `sendreceive` on a controlled folder, it is a **violation**. You must transfer master to the correct device or fix the folder type manually.

### 2. Initialization (First-time Setup)
When adding a new device or reinstalling an OS:
```bash
# Set the current device as the initial Master
syncctl init <device_name>
```
*Note: This skips certain cluster checks as other devices may not be online yet.*

### 3. Safe Handover (Master Transfer)
To move the Master role to another device:
1.  **Dry-run first** to see what will happen:
    ```bash
    syncctl transfer <target_device> --dry-run
    ```
2.  **Execute the transfer** (requires a reason for audit):
    ```bash
    syncctl transfer <target_device> --reason "Moving work to Windows"
    ```
**Quality Check:** The tool performs a mandatory **Checkpoint** (4 checks) before proceeding. If the checkpoint fails, the transfer is aborted.

### 4. Break-glass Transfer
If the current Master is offline/unreachable for a long time:
```bash
syncctl transfer <target_device> --force --reason "Master is dead"
```
*Warning: This bypasses some safety checks and requires manual confirmation.*

### 5. Conflict Resolution
```bash
# List all .sync-conflict-* files
syncctl conflicts

# Resolve a specific conflict (archive and remove)
syncctl resolve <filename> --keep newer
```

## Maintenance & Recovery
- **Recover:** If a handover was interrupted (e.g., crash), use `syncctl recover` to view and fix stale states.
- **Logs:** View the audit trail with `syncctl logs`.
- **Locking:** `syncctl lock/unlock` can be used to prevent transfers during maintenance.

## SSOT Reference
- **Device IDs:** Defined in `00-env.sh` (`NODE_*_ST_ID`).
- **API Keys:** Defined in `00-env.sh` (`ST_KEY_*`).
- **Folder ID:** Configured in `tools/syncctl/lib/config.sh` (`SYNCCTL_FOLDER_ID`).
