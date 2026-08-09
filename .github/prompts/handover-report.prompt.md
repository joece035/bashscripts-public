---
description: "Generate a summary report of the last Syncthing master handover."
argument-hint: "[optional reason or target device]"
tools: [terminal, search]
---

# Syncthing Handover Report

Generate a concise report of the last `syncctl` handover based on the current state and audit logs.

## 1. Current State
Run `syncctl status` to identify the current master and cluster state.
Run `syncctl doctor` to check for any immediate violations or sync issues.

## 2. Handover History
Read the last 20 lines of the syncctl audit log (`syncctl logs`) to identify:
- The **Previous Master** and **New Master**.
- The **Reason** provided for the transfer.
- The **Timestamp** of the event.
- Any **Checkpoint** or **Lock** messages.

## 3. Summary Format
Present the findings in the following Markdown structure:

### 🛡️ Handover Summary
- **Date:** [Timestamp]
- **Action:** [Previous Master] → [New Master]
- **Reason:** [User-provided reason]
- **Status:** [Success / In-Progress / Failed]

### 🔍 Cluster Health
- **Current Master:** [Device Name]
- **Sync Status:** [Synced / Paused / Error]
- **Violations:** [None / List of violations]

### 📝 Audit Trail (Last 5 entries)
[Table of recent log entries]

## 4. Next Steps (if applicable)
- If there are unresolved conflicts, suggest `syncctl conflicts`.
- If a handover was interrupted, suggest `syncctl recover`.
