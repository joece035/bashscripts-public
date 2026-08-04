# `syncctl` Engineering Fix Report

## Safe Master Handover, State Authority & Fail-Closed Behavior

## Objective

ปรับปรุง `syncctl` ให้เป็นระบบควบคุม Syncthing ที่ **ปลอดภัยต่อข้อมูลและ ownership state**

หลักการสูงสุดของระบบคือ:

> **เมื่อระบบไม่สามารถพิสูจน์ได้ว่า Master คือใคร ระบบต้องหยุดและห้ามเดา**

ห้ามเลือก Master อัตโนมัติจาก state ที่ขัดแย้งกัน

```text
AMBIGUOUS STATE
      ↓
     STOP
      ↓
NO STATE MUTATION
      ↓
REQUIRE OPERATOR ACTION
```

---

# 1. CRITICAL INVARIANT: Never Have Two Masters

ปัจจุบัน handover flow มีความเสี่ยงที่จะเกิดช่วง:

```text
OLD MASTER = SEND ONLY
TARGET      = SEND ONLY
```

เพราะ implementation promote target ก่อน แล้วค่อย demote old master

ตัวอย่าง:

```text
Before:

WSL       SEND ONLY
Windows   RECEIVE ONLY
Termux    RECEIVE ONLY
```

ถ้า promote Windows ก่อน:

```text
WSL       SEND ONLY
Windows   SEND ONLY    ← INVALID
Termux    RECEIVE ONLY
```

นี่ต้องถูกแก้

## Required invariant

ระบบต้องรักษากฎ:

```text
MASTER COUNT <= 1
```

และใน normal operation:

```text
MASTER COUNT = 1
```

ระหว่าง handover อนุญาตให้มี:

```text
MASTER COUNT = 0
```

ชั่วคราวได้

แต่ **ห้าม MASTER COUNT > 1**

---

# 2. Required Handover Order

เปลี่ยน handover protocol ให้เป็น:

```text
PRECHECK
    ↓
CHECKPOINT
    ↓
LOCK
    ↓
VERIFY TARGET
    ↓
FREEZE OLD MASTER
    ↓
DEMOTE OLD MASTER
    ↓
VERIFY OLD MASTER = RECEIVE ONLY
    ↓
PROMOTE TARGET
    ↓
VERIFY TARGET = SEND ONLY
    ↓
VERIFY ALL OTHER DEVICES = RECEIVE ONLY
    ↓
COMMIT NEW MASTER
    ↓
POST-CHECKPOINT
```

สำคัญ:

> **Do not promote the target while the old master is still SEND ONLY.**

---

# 3. Checkpoint Is a Gate, Not a Suggestion

ก่อน transfer ทุกครั้งต้องมี checkpoint

```text
syncctl transfer windows
```

ต้อง internally perform:

```text
checkpoint
    ↓
PASS?
 ┌──┴──┐
NO    YES
│      │
ABORT  CONTINUE
```

ถ้า checkpoint fail:

```text
⛔ TRANSFER ABORTED

Checkpoint failed.

Master remains: WSL
```

ห้าม:

* เปลี่ยน folder type
* เปลี่ยน Master state
* update authoritative state
* promote target

---

# 4. Checkpoint Must Verify Actual State

Checkpoint ต้องตรวจอย่างน้อย:

```text
1. Local state
2. Syncthing sync state
3. Peer / cluster state
4. Conflict state
5. Folder ownership/type
6. Master identity
```

ตัวอย่าง expected state:

```text
WSL       SEND ONLY       CLEAN
Windows   RECEIVE ONLY    CLEAN
Termux    RECEIVE ONLY    CLEAN
```

หากพบ:

```text
OUT OF SYNC
CONFLICT
UNKNOWN
MISMATCH
UNREACHABLE
```

ให้:

```text
CHECKPOINT = FAIL
```

และ **ห้าม transfer**

---

# 5. CRITICAL: Never Automatically Resolve Ownership Conflicts

พบ logic ลักษณะนี้:

```bash
if [[ "$local_m" != "$synced_m" ]]; then
    state_set_local_master "$synced_m"
fi
```

ต้องลบ / เปลี่ยน behavior

นี่คือ dangerous behavior

ถ้า:

```text
LOCAL MASTER  = WSL
SYNCED MASTER = Windows
```

ระบบ **ไม่มีสิทธิ์เลือก Windows อัตโนมัติ**

## Required behavior

```text
⛔ OWNERSHIP STATE CONFLICT

Local master:
    WSL

Synced master:
    Windows

The authoritative master cannot be determined automatically.

NO CHANGES HAVE BEEN MADE.
```

ต้อง:

```text
ABORT
NO STATE MUTATION
```

---

# 6. Fail Closed

หลักการนี้ต้องใช้ทั่วทั้ง project:

> **When state is ambiguous, fail closed. Never guess ownership.**

กรณีต่อไปนี้ต้อง fail closed:

```text
local master != authoritative master
folder type mismatch
peer state mismatch
checkpoint mismatch
conflict detected
unexpected state
unknown state
incomplete synchronization
authoritative state unavailable
```

ห้ามทำ:

```text
"เลือกค่าที่น่าจะถูก"
"ใช้ synced state"
"ใช้ local state"
"เลือกเครื่องที่ online"
"เลือกเครื่องล่าสุด"
```

ไม่มี heuristic สำหรับ ownership

---

# 7. State Conflict Must Not Be Auto-Reconciled

ถ้าเจอ:

```text
local = wsl
synced = windows
```

ห้าม:

```text
synced wins
local wins
latest wins
online wins
majority wins
```

เพราะระบบไม่สามารถรู้ intent ของ operator ได้

ต้องเปลี่ยนเป็น:

```text
CONFLICT
   ↓
STOP
   ↓
PRESERVE STATE
   ↓
REPORT
   ↓
OPERATOR RECOVERY
```

---

# 8. Authoritative State Must Be Clearly Defined

ตรวจสอบ architecture ของ `.syncctl/master`

หาก `.syncctl/master` อยู่ภายใน Syncthing folder ที่กำลังถูกควบคุมอยู่:

```text
syncctl
   ↓
changes master state
   ↓
Syncthing syncs master state
   ↓
other syncctl instances receive master state
```

นี่ทำให้ control-plane state ถูกนำไปอยู่ใน data-plane

ให้พิจารณาแยก:

```text
CONTROL PLANE

~/.local/share/syncctl/
    state/
    checkpoints/
    audit/
    locks/
```

ออกจาก:

```text
DATA PLANE

bashscripts/
```

ห้ามใช้ replicated data เป็น authoritative ownership source โดยไม่มีกลไกที่พิสูจน์ authority ได้

---

# 9. Checkpoint Must Record State Evidence

Checkpoint ไม่ควรบันทึกแค่:

```json
{
  "result": "pass"
}
```

ต้องบันทึก state ที่ถูกตรวจสอบ

ตัวอย่าง:

```json
{
  "id": "0042",
  "master": "wsl",
  "folder": "bashscripts",
  "devices": {
    "wsl": {
      "type": "sendonly",
      "state": "clean"
    },
    "windows": {
      "type": "receiveonly",
      "state": "clean"
    },
    "termux": {
      "type": "receiveonly",
      "state": "clean"
    }
  },
  "conflicts": 0,
  "result": "pass",
  "timestamp": "..."
}
```

จุดประสงค์คือ:

> Checkpoint ต้องบอกได้ว่า **ระบบพิสูจน์อะไรไว้ ณ เวลานั้น**

ไม่ใช่แค่บอกว่า `PASS`

---

# 10. Checkpoint ID Must Be Safe

ตรวจสอบ checkpoint counter

ห้ามใช้ logic ที่มี race condition:

```bash
read counter
counter=$((counter + 1))
write counter
```

โดยไม่มี locking

ต้องทำให้ checkpoint creation atomic

หรือใช้ lock mechanism ที่มีอยู่แล้ว

เป้าหมาย:

```text
parallel checkpoint
      ↓
NO DUPLICATE CHECKPOINT ID
```

---

# 11. Post-Checkpoint Failure Must Not Report Success

ปัจจุบันมี behavior ลักษณะ:

```text
post-checkpoint failed
      ↓
print warning
      ↓
Transfer complete
      ↓
exit 0
```

ห้ามทำแบบนี้

ถ้า:

```text
POST-CHECKPOINT = FAIL
```

ผลลัพธ์ต้องไม่เป็น:

```text
SUCCESS
exit 0
```

ควรเป็นสถานะที่ชัดเจน เช่น:

```text
⚠️ TRANSFER INCOMPLETE

Target promotion:
    ✓

Old master demotion:
    ✓

Final verification:
    ✗

Post-checkpoint:
    ✗

System state:
    DEGRADED / UNVERIFIED
```

และ return non-zero

---

# 12. Rollback Must Be Real Rollback

หากระบบประกาศ:

```text
ROLLBACK
```

ต้อง restore state จริง

ไม่ใช่แค่:

```bash
state_handover_complete
```

การ rollback ต้องพิจารณา:

```text
old master folder type
target folder type
other peer folder types
authoritative state
handover state
```

แล้ว verify หลัง rollback

ตัวอย่าง:

```text
ROLLBACK

WSL:
    SEND ONLY ✓

Windows:
    RECEIVE ONLY ✓

Termux:
    RECEIVE ONLY ✓

Master:
    WSL ✓

Cluster:
    VERIFIED ✓
```

หาก rollback ไม่สามารถทำให้ระบบกลับสู่ known-good state:

```text
RECOVERY REQUIRED
```

ห้ามโกหกว่า rollback สำเร็จ

---

# 13. Recovery Must Understand Interrupted Handover

ต้องรองรับ process crash ระหว่าง:

```text
DEMOTE OLD
PROMOTE TARGET
VERIFY
COMMIT
```

ตัวอย่าง:

```text
OLD MASTER:
    WSL

TARGET:
    Windows

Process killed after:

WSL       RECEIVE ONLY
Windows   SEND ONLY
```

เมื่อ:

```bash
syncctl recover
```

ต้อง:

1. อ่าน handover journal/state
2. ตรวจ actual Syncthing state
3. ไม่เดาว่า operation สำเร็จ
4. ไม่เดาว่า operation ล้มเหลว
5. Determine whether state matches known transition
6. Recover หรือหยุดเพื่อ operator intervention
7. Verify final state

---

# 14. `--force` Must Be Treated As Break-Glass

หากมี:

```bash
syncctl transfer windows --force
```

ต้องไม่หมายความว่า:

```text
skip safety checks
and continue normally
```

ให้ถือว่า:

```text
BREAK-GLASS OPERATION
```

ต้องแสดง warning:

```text
⚠️ BREAK-GLASS MODE

Normal checkpoint cannot be established.

This operation cannot guarantee normal ownership safety.

Explicit override required.
```

และต้องบันทึก audit event

ห้ามใช้ `--force` เพื่อ bypass ownership ambiguity แบบเงียบๆ

---

# 15. Handover Must Be Transaction-Like

ต้องมี explicit states เช่น:

```text
IDLE
PRECHECK
CHECKPOINTING
LOCKED
VERIFYING_TARGET
DEMOTING_OLD
PROMOTING_TARGET
VERIFYING
COMMITTING
POST_CHECKPOINT
COMPLETE
FAILED
RECOVERY_REQUIRED
```

อย่าใช้เพียง boolean:

```text
handover_in_progress=true
```

เพื่อแทนทุกอย่าง

ระบบต้องรู้ว่าตายอยู่ขั้นไหน

---

# 16. Commit Point

ต้องมีจุด commit ที่ชัดเจน

ก่อน commit:

```text
handover_in_progress = true
```

หลังจาก:

```text
old master verified receiveonly
target verified sendonly
all peers verified receiveonly
```

เท่านั้น:

```text
COMMIT
```

หลัง commit:

```text
master = target
handover_in_progress = false
```

ถ้าตายก่อน commit:

```text
RECOVERY_REQUIRED
```

ไม่ควรตีความว่า transfer สำเร็จโดยอัตโนมัติ

---

# 17. Status Must Detect Ambiguity

`syncctl status` ต้องไม่พยายามซ่อน state conflict

ตัวอย่าง:

```text
$ syncctl status

⛔ SYSTEM STATE: CONFLICT

Local authority:
    WSL

Synced authority:
    Windows

Master:
    UNKNOWN

Action:
    Recovery required

NO CHANGES HAVE BEEN MADE.
```

ดีกว่าแสดง:

```text
MASTER: Windows
```

ทั้งที่ระบบยังพิสูจน์ไม่ได้

---

# 18. Tests Required

เพิ่ม test cases สำหรับ safety invariants

## Test A: Normal transfer

```text
WSL → Windows
```

Expected:

```text
PASS
Windows = SEND ONLY
WSL = RECEIVE ONLY
Termux = RECEIVE ONLY
```

## Test B: Never two masters

During every handover step:

```text
master_count <= 1
```

ต้อง test state transition โดยตรง

## Test C: Checkpoint failure

```text
conflict exists
```

Expected:

```text
transfer aborted
master unchanged
no state mutation
```

## Test D: Ownership conflict

```text
local master = wsl
synced master = windows
```

Expected:

```text
ABORT
NO AUTOMATIC RESOLUTION
NO STATE MUTATION
```

## Test E: Target out of sync

Expected:

```text
ABORT
```

## Test F: Old master demotion failure

Expected:

```text
ABORT
RECOVERY REQUIRED or rollback
NEVER silently continue
```

## Test G: Target promotion failure

Expected:

```text
RECOVERY REQUIRED
```

## Test H: Post-checkpoint failure

Expected:

```text
non-zero exit
NOT SUCCESS
```

## Test I: Process killed during handover

Simulate termination at every transition:

```text
before demotion
after demotion
before promotion
after promotion
before commit
after commit
```

Then run:

```bash
syncctl recover
```

Expected result must be deterministic and safe.

## Test J: Concurrent transfer

Run:

```bash
syncctl transfer windows &
syncctl transfer termux &
```

Expected:

```text
only one operation acquires lock
other operation aborts
```

---

# 19. Test Environment Dependencies

The test suite may depend on external/shared shell utilities such as:

```text
01-color.sh
```

Do NOT interpret a missing environment dependency as an application logic failure.

Tests must either:

1. explicitly load required environment dependencies, or
2. provide a self-contained test fixture/mock for those dependencies.

The test report must clearly distinguish:

```text
APPLICATION TEST FAILURE
```

from:

```text
TEST ENVIRONMENT / DEPENDENCY FAILURE
```

Do not modify application logic merely to hide a missing test dependency.

---

# 20. Test Report Requirements

After fixing, run the complete test suite.

Report:

```text
Environment:
    OS:
    Bash:
    Syncthing:
    Test dependencies:

Tests:
    Passed:
    Failed:
    Skipped:

Safety invariants:
    Single master:
    Fail closed:
    No auto ownership resolution:
    Rollback:
    Recovery:
    Concurrent lock:
```

Do not claim:

```text
All tests passed
```

unless the complete suite actually ran.

---

# 21. Definition of Done

This task is complete only when all of the following are true:

### Ownership

```text
✓ At most one SEND ONLY master
✓ No automatic ownership guessing
✓ Ambiguous ownership = STOP
```

### Checkpoint

```text
✓ Required before normal handover
✓ Captures evidence
✓ Detects conflicts
✓ Detects inconsistent peers
✓ Safe checkpoint IDs
```

### Handover

```text
✓ Old master demoted before target promotion
✓ Never two masters
✓ Target verified before commit
✓ All peers verified
✓ Explicit commit point
```

### Recovery

```text
✓ Interrupted handover detectable
✓ Rollback actually restores state
✓ Recovery never guesses
✓ Unknown state → RECOVERY_REQUIRED
```

### Failure semantics

```text
✓ Failed checkpoint → non-zero
✓ Failed post-checkpoint → non-zero
✓ Failed handover → non-zero
✓ No false "Transfer complete"
```

### Testing

```text
✓ Complete test suite runs
✓ Environment dependencies documented
✓ Failure scenarios tested
✓ Process interruption tested
✓ Concurrent operations tested
```

---

# Final Design Rule

This rule overrides convenience:

```text
┌─────────────────────────────────────────────┐
│                                             │
│  IF OWNERSHIP STATE IS AMBIGUOUS:           │
│                                             │
│       DO NOT GUESS                           │
│       DO NOT AUTO-RECONCILE                 │
│       DO NOT MUTATE STATE                   │
│                                             │
│       FAIL CLOSED                           │
│       REPORT THE CONFLICT                   │
│       REQUIRE RECOVERY / OPERATOR ACTION    │
│                                             │
└─────────────────────────────────────────────┘
```

The purpose of `syncctl` is not merely to make Syncthing continue operating.

Its primary responsibility is:

> **Prevent an incorrect ownership decision from causing data corruption or silent state divergence.**

Do not add new features until the above safety invariants and tests are implemented and passing.
