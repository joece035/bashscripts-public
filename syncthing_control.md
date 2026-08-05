# Task: Build `syncctl` — Safe Syncthing Master / Ownership Controller

## Goal

สร้าง CLI tool ชื่อ `syncctl` สำหรับควบคุม Syncthing หลายเครื่อง โดยมีแนวคิดหลักคือ:

> **ในช่วงเวลาใดเวลาหนึ่ง ต้องมีเครื่องเดียวเท่านั้นที่เป็น `MASTER / Source of Truth`**

เครื่องอื่นต้องอยู่ในสถานะ `RECEIVE ONLY`

จุดประสงค์หลักคือป้องกันปัญหา Syncthing conflict ที่เกิดจากการแก้ไฟล์จากหลายเครื่องพร้อมกัน แล้วไฟล์เวอร์ชันเก่าถูก sync กลับมาอีก

ตัวอย่าง environment:

```text
WSL
Windows
Termux
```

folder ตัวอย่าง:

```text
bashscripts
```

---

# Core Architecture

ต้องออกแบบระบบเป็นแนวคิด:

```text
                 MASTER
                   │
                SEND ONLY
                   │
          ┌────────┴────────┐
          ▼                 ▼
     RECEIVE ONLY      RECEIVE ONLY
       Windows            Termux
```

ห้ามมีหลายเครื่องเป็น writable source พร้อมกัน

ตัวอย่างเมื่อ WSL เป็น Master:

```text
WSL       = SEND ONLY
Windows   = RECEIVE ONLY
Termux    = RECEIVE ONLY
```

เมื่อย้าย Master ไป Windows:

```text
Windows   = SEND ONLY
WSL       = RECEIVE ONLY
Termux    = RECEIVE ONLY
```

---

# IMPORTANT: Do NOT start coding immediately

ก่อนเขียน implementation ให้:

1. วิเคราะห์ requirements
2. ออกแบบ state machine
3. ออกแบบ checkpoint mechanism
4. ออกแบบ master handover protocol
5. ออกแบบ failure / rollback behavior
6. เสนอ architecture
7. เสนอ CLI interface
8. จากนั้นค่อย implement

ห้ามแก้ปัญหาด้วยการเขียน Bash ยาวๆ โดยไม่มี state model

---

# 1. Master Concept

ระบบต้องมี concept:

```text
MASTER
SOURCE OF TRUTH
RECEIVE ONLY
CHECKPOINT
HANDOVER
LOCK
```

Master คือเครื่องเดียวที่มีสิทธิ์แก้ไขไฟล์ต้นฉบับ

เครื่องอื่นเป็น replicas

---

# 2. Checkpoint System

นี่คือส่วนที่สำคัญที่สุด

ก่อนเปลี่ยน Master:

> **ต้องสร้างและผ่าน CHECKPOINT ก่อนเสมอ**

ห้าม transfer ถ้า checkpoint ไม่ผ่าน

Workflow:

```text
Current Master
      │
      ▼
CHECKPOINT
      │
      ├── LOCAL STATE
      ├── SYNC STATE
      ├── CLUSTER STATE
      └── CONFLICT STATE
      │
      ▼
VERIFY
      │
   PASS?
   ┌──┴──┐
  NO    YES
  │      │
 STOP   HANDOVER
```

---

# 3. Checkpoint Requirements

Checkpoint ต้องตรวจอย่างน้อย:

## 3.1 Local State

ตรวจว่าเครื่อง Master ไม่มี pending local changes ที่ยังไม่ถูกจัดการ

```text
LOCAL = CLEAN
```

## 3.2 Syncthing Sync State

ตรวจว่า Syncthing sync เสร็จสมบูรณ์

ต้องไม่มี:

```text
out of sync
pending changes
unfinished synchronization
```

## 3.3 Cluster State

ตรวจว่า peer ทุกเครื่องมี state ที่ตรงกัน

ตัวอย่าง:

```text
WSL       CLEAN
Windows   CLEAN
Termux    CLEAN
```

## 3.4 Conflict Detection

ตรวจหา conflict files เช่น:

```text
*.sync-conflict-*
```

และตรวจ state ที่เกี่ยวข้องกับ conflict ผ่าน Syncthing API

ถ้ามี conflict:

```text
CHECKPOINT = FAIL
```

ห้าม transfer

---

# 4. Checkpoint Must Produce Evidence

อย่าให้ checkpoint เป็นเพียง:

```text
✓ looks good
```

ต้องสามารถบันทึก checkpoint metadata ได้

ตัวอย่าง:

```text
CHECKPOINT #0042

MASTER: WSL
FOLDER: bashscripts

WSL       CLEAN
WINDOWS   CLEAN
TERMUX    CLEAN

CONFLICTS: 0

TIMESTAMP: ...
STATE ID: ...
```

Checkpoint ควรมี unique ID และ timestamp

ถ้าเหมาะสม ให้เก็บ state/hash ที่ช่วยยืนยันว่า state หลัง checkpoint ไม่เปลี่ยนโดยไม่ได้ตั้งใจ

---

# 5. CLI

ออกแบบ CLI ให้เรียบง่าย

ขั้นต่ำต้องมี:

```bash
syncctl status
syncctl who
syncctl checkpoint
syncctl transfer <device>
syncctl lock
syncctl unlock
```

---

# 6. `syncctl status`

แสดงสถานะทั้งหมด

ตัวอย่าง:

```text
╭────────────────────────────────────────────╮
│ SYNC CONTROL                               │
├────────────────────────────────────────────┤
│ MASTER                                     │
│   ● WSL                                    │
│                                            │
│ DEVICES                                    │
│   WSL       SEND ONLY       ✓ MASTER       │
│   Windows   RECEIVE ONLY   ✓ SYNCED        │
│   Termux    RECEIVE ONLY   ✓ SYNCED        │
│                                            │
│ FOLDER                                     │
│   bashscripts                              │
│                                            │
│ CHECKPOINT                                 │
│   #0042                                    │
│                                            │
│ STATE                                      │
│   ● CLEAN                                  │
╰────────────────────────────────────────────╯
```

---

# 7. `syncctl who`

ต้องบอกว่า Master คือใคร

```bash
syncctl who
```

output:

```text
WSL
```

หรือ:

```text
MASTER: WSL
```

---

# 8. `syncctl checkpoint`

คำสั่งนี้:

```bash
syncctl checkpoint
```

ต้อง:

1. ตรวจ current Master
2. ตรวจ local state
3. ตรวจ Syncthing state
4. ตรวจ peer state
5. ตรวจ conflicts
6. ตรวจ consistency
7. ถ้าผ่าน สร้าง checkpoint ID
8. ถ้าไม่ผ่าน ห้าม modify ownership state

Success:

```text
CHECKPOINT #0042

✓ Local state
✓ Syncthing state
✓ Cluster state
✓ Conflict check
✓ Consistency

CHECKPOINT PASSED
```

Failure:

```text
⛔ CHECKPOINT FAILED

WSL       ✓ CLEAN
Windows   ✓ CLEAN
Termux    ✗ OUT OF SYNC

Master remains: WSL
```

---

# 9. `syncctl transfer <device>`

ตัวอย่าง:

```bash
syncctl transfer windows
```

ต้องทำ safe handover

ห้ามแค่เปลี่ยน Syncthing mode ทันที

Workflow:

```text
1. Detect current Master
2. Validate requested target
3. Create checkpoint
4. If checkpoint FAIL → ABORT
5. Freeze / lock current ownership
6. Ensure source state is stable
7. Ensure target has received current state
8. Promote target
9. Set target = SEND ONLY
10. Set all other devices = RECEIVE ONLY
11. Verify resulting cluster state
12. Create new checkpoint
13. Report success
```

---

# 10. Transfer MUST Abort Safely

ถ้าขั้นตอนใดไม่ผ่าน:

```text
ABORT
```

ห้ามฝืนทำต่อ

ตัวอย่าง:

```text
$ syncctl transfer windows

⛔ TRANSFER ABORTED

Checkpoint failed:

  WSL       ✓ CLEAN
  Windows   ✓ CLEAN
  Termux    ✗ OUT OF SYNC
  Conflict  ✗ 2 files

Master remains: WSL
```

หลักการ:

> **If uncertain, do not change ownership.**

---

# 11. Ownership State Machine

ออกแบบ state machine อย่างชัดเจน

ตัวอย่าง:

```text
                    ┌───────────┐
                    │   LOCKED  │
                    └─────┬─────┘
                          │
                          ▼
                  ┌───────────────┐
                  │ MASTER = WSL  │
                  └───────┬───────┘
                          │
                    transfer windows
                          │
                          ▼
                  ┌───────────────┐
                  │  CHECKPOINT   │
                  └───────┬───────┘
                          │
                     PASS / FAIL
                      │       │
                     FAIL     PASS
                      │       │
                      ▼       ▼
                    ABORT   HANDOVER
                              │
                              ▼
                     MASTER = WINDOWS
```

ต้องนิยาม valid และ invalid transitions

---

# 12. Locking

ต้องมีระบบ lock เพื่อป้องกันการเปลี่ยน Master พร้อมกัน

ตัวอย่าง:

```bash
syncctl lock
```

เมื่อ locked:

```text
MASTER = WSL
WRITABLE = WSL
OTHERS = RECEIVE ONLY
```

ไม่ควรอนุญาตให้ transfer ซ้อนกัน

ต้องมี protection against race conditions เช่น:

```text
syncctl transfer windows
syncctl transfer termux
```

ถูกเรียกพร้อมกัน

---

# 13. Syncthing Integration

ให้ใช้ Syncthing REST API เป็นหลัก

**ห้ามแก้ `config.xml` โดยตรงถ้าไม่จำเป็น**

ต้องศึกษา API ที่เหมาะสมสำหรับ:

* อ่าน folder configuration
* เปลี่ยน folder type
* ตรวจ sync status
* ตรวจ peer status
* ตรวจ global/local state
* ตรวจ errors/conflicts
* trigger override เมื่อจำเป็น
* reload/restart configuration เมื่อจำเป็น

ใช้:

```text
sendonly
receiveonly
```

เป็น primitive หลักของ ownership model

---

# 14. Important Safety Rule

อย่าใช้ `sendreceive` สำหรับ folder ที่อยู่ภายใต้ ownership control

ต้องทำให้ architecture เป็น:

```text
MASTER
  ↓
SEND ONLY
  ↓
RECEIVE ONLY peers
```

ไม่ใช่:

```text
WSL       SEND/RECEIVE
Windows   SEND/RECEIVE
Termux    SEND/RECEIVE
```

เพราะนั่นทำให้หลายเครื่องมีสิทธิ์เป็น writer และเปิดประตูให้ conflict กลับมา

---

# 15. Configuration

อย่า hardcode device information ใน source code

ออกแบบ config เช่น:

```yaml
folder:
  id: bashscripts

devices:
  wsl:
    name: WSL
    syncthing_api: ...
  windows:
    name: Windows
    syncthing_api: ...
  termux:
    name: Termux
    syncthing_api: ...
```

แต่เลือก format ที่เหมาะสมกับ implementation

Secrets/API keys ต้องไม่ถูก commit ลง repository

---

# 16. Architecture Requirements

แยก concerns ให้ชัดเจน:

```text
syncctl
│
├── config
│
├── syncthing API client
│
├── device manager
│
├── state manager
│
├── checkpoint engine
│
├── conflict detector
│
├── ownership manager
│
├── handover engine
│
├── lock manager
│
└── CLI / renderer
```

ห้ามรวมทุกอย่างไว้ใน function เดียว

---

# 17. Idempotency

คำสั่งต้องปลอดภัยเมื่อรันซ้ำ

ตัวอย่าง:

```bash
syncctl transfer windows
```

ถ้า Windows เป็น Master อยู่แล้ว:

```text
✓ Windows is already MASTER
No action required.
```

ไม่ควรทำ state transition ซ้ำโดยไม่จำเป็น

---

# 18. Failure Recovery

ต้องคิดกรณี:

* Syncthing API unreachable
* peer offline
* network disconnect
* sync incomplete
* conflict detected
* target device offline
* target state mismatch
* API timeout
* transfer interrupted midway
* process killed during handover
* machine rebooted during handover

ต้องออกแบบ recovery strategy

**ห้ามสมมติว่า network จะดีตลอดเวลา**

---

# 19. Dry Run

เพิ่ม:

```bash
syncctl transfer windows --dry-run
```

ให้แสดงสิ่งที่จะเกิดขึ้นโดยไม่เปลี่ยน state

ตัวอย่าง:

```text
DRY RUN

Current Master : WSL
Target Master  : Windows

Checkpoint     : PASS
Windows state  : CLEAN

Planned changes:

  WSL       SEND ONLY → RECEIVE ONLY
  Windows   RECEIVE ONLY → SEND ONLY
  Termux    RECEIVE ONLY

No changes applied.
```

---

# 20. Debug Mode

เพิ่ม:

```bash
syncctl --debug status
```

และควรมี logging ที่ช่วย trace handover

เช่น:

```text
[14:02:11] Current master: WSL
[14:02:11] Running checkpoint
[14:02:12] Local state: CLEAN
[14:02:12] Cluster state: CLEAN
[14:02:12] Conflicts: 0
[14:02:12] Checkpoint #0042 created
[14:02:13] Lock acquired
[14:02:14] Promoting Windows
...
```

---

# 21. Testing

ต้องสร้าง test cases อย่างน้อย:

### Normal

```text
WSL → Windows
Windows → Termux
Termux → WSL
```

### Failure

```text
peer offline
conflict exists
sync incomplete
API unavailable
network unavailable
target not synced
transfer interrupted
```

### Safety

ทดสอบว่า:

```text
checkpoint FAIL
    ↓
Master MUST NOT change
```

และ:

```text
transfer interrupted
    ↓
system MUST NOT silently claim success
```

---

# 22. Most Important Design Principle

ระบบนี้ไม่ได้มีหน้าที่แค่ "สั่ง Syncthing"

แต่มีหน้าที่ควบคุม:

```text
OWNERSHIP
CONSISTENCY
CHECKPOINT
HANDOVER
SAFETY
```

ดังนั้นให้คิดว่า `syncctl` เป็น **control plane สำหรับ Syncthing**

Syncthing = data synchronization engine

`syncctl` = ownership / safety controller

---

# 23. Folder Type Reconciliation (added 2026-08-05)

## ปัญหา

`syncctl doctor` แจ้งว่า folder type ของ device หนึ่ง (เช่น termux) ไม่ตรงกับที่ควรเป็น

เช่น: `master=wsl` แต่ `termux` เป็น `sendreceive` แทนที่จะเป็น `receiveonly`

**สาเหตุหลัก:** ตอน onboard device ใหม่ ลืม set folder type ให้ถูก
หรือ Syncthing default เป็น `sendreceive` แล้วลืม override

**ผลกระทบ:** device ที่เป็น `sendreceive` สามารถแก้ไขไฟล์ได้ → เกิด conflict กับ master

## Design Decision 23.1: `fix-types` vs `transfer`

`transfer` มีจุดประสงค์เพื่อ **ย้าย master** (เขียน state.json, two-phase commit, recoverable)

แต่กรณีนี้ **master ไม่เปลี่ยน** → แค่ "fix folder type ให้ตรงกับ master"

จึงสร้าง subcommand ใหม่: `syncctl fix-types`

| | `transfer` | `fix-types` |
|---|---|---|
| เปลี่ยน master pointer? | ✅ Yes | ❌ No |
| เขียน state.json? | ✅ Yes (HANDOVER_IN_PROGRESS) | ❌ No |
| Touch ทุก device folder type? | ✅ Yes (เพราะต้อง demote/promote) | ✅ Yes (reconcile ตาม master) |
| Recovery menu เกี่ยวข้อง? | ✅ Yes (stale handover detection) | ❌ No |
| Idempotent? | ✅ Yes (already master = noop) | ✅ Yes (already correct = noop) |
| Dry-run? | ✅ Yes | ✅ Yes |
| Locked? | ✅ Yes | ✅ Yes (กัน race กับ transfer) |

## Design Decision 23.2: `set-type` เป็น escape hatch

บางครั้งต้อง set type แค่ device เดียวโดยไม่ต้อง reconcile cluster

เช่น: อยาก `sendreceive` termux ชั่วคราวเพื่อ test (อย่า! แต่ถ้าจำเป็น)

`syncctl set-type <dev> <sendonly|receiveonly|sendreceive>` ทำหน้าที่นี้

**Idempotent:** ถ้า device อยู่ type นั้นอยู่แล้ว → noop (log audit, ไม่เรียก API)

**Validation:** reject type ที่ไม่ใช่ 3 ตัวเลือกนี้

## Design Decision 23.3: `types` เป็น read-only inspect

`syncctl types` แสดง ownership table (DEVICE | CURRENT | EXPECTED | STATUS)

ต่างจาก `status` ที่แสดงภาพรวม:
- `status` = dashboard (master, sync %, checkpoint, conflicts)
- `types` = folder type only (current vs expected vs mismatch)

ใช้ `types` เมื่อต้องการ focus เฉพาะ folder type

## Implementation Notes

### `fix_types` function (lib/ownership.sh)

```bash
fix_types() {
    # 1. Resolve master (FAIL if uninit or state conflict)
    # 2. Acquire lock
    # 3. Loop: for each device, compare current vs expected
    #    - If match → skip
    #    - If mismatch → PATCH via API (skip if dry-run)
    # 4. Log audit + report
    # 5. Release lock
}
```

### `set_type_device` function (lib/ownership.sh)

```bash
set_type_device() {
    # 1. Validate device name (known_device check)
    # 2. Validate type (sendonly|receiveonly|sendreceive)
    # 3. Get current type (via get_folder_type)
    # 4. If already at target → noop (audit only)
    # 5. Else → PATCH via set_folder_type (which validates again)
}
```

### Tests (tests/run.sh)

4 new tests:
- `test_fix_types_dry_run` — verify no API calls + preview output
- `test_fix_types_idempotent` — re-run is noop
- `test_set_type_valid` — set one device, verify mock state
- `test_set_type_invalid_rejected` — garbage type rejected, no state change

Total: 30 → 34 tests

---

# Expected Final UX

ผู้ใช้ควรสามารถทำแบบนี้ได้:

```bash
syncctl status
```

ดูว่าใครเป็น Master

จากนั้น:

```bash
syncctl checkpoint
```

ตรวจว่า state clean

แล้ว:

```bash
syncctl transfer windows
```

ระบบทำ safe handover ให้เอง

สุดท้าย:

```bash
syncctl status
```

ได้:

```text
MASTER

  Windows ✓

DEVICES

  Windows   SEND ONLY       ✓ MASTER
  WSL       RECEIVE ONLY    ✓ SYNCED
  Termux    RECEIVE ONLY    ✓ SYNCED

CHECKPOINT

  #0043 ✓ CLEAN
```

---

# Implementation Strategy

**Phase 1**

ทำ design document ก่อน

ส่งกลับมา:

1. Architecture
2. State machine
3. Checkpoint model
4. Handover protocol
5. Failure scenarios
6. Config schema
7. CLI design

**ห้ามเขียน implementation จนกว่าจะสรุป design เหล่านี้เสร็จ**

**Phase 2**

Implement Syncthing API client

**Phase 3**

Implement checkpoint engine

**Phase 4**

Implement ownership manager

**Phase 5**

Implement handover

**Phase 6**

Implement CLI / status renderer

**Phase 7**

Implement tests และ failure simulation

---

# Definition of Done

ถือว่างานเสร็จเมื่อ:

* มี Master ได้เพียงหนึ่งเครื่อง
* Master เป็น `sendonly`
* เครื่องอื่นเป็น `receiveonly`
* มี checkpoint ก่อนทุก handover
* checkpoint fail → transfer abort
* ตรวจ conflict ได้
* ตรวจ sync consistency ได้
* transfer มี safe state transition
* มี lock ป้องกัน concurrent transfer
* มี dry-run
* มี status
* มี logging
* มี failure recovery
* มี tests
* ไม่มี secret hardcoded
* ไม่แก้ Syncthing config XML โดยตรงโดยไม่จำเป็น

และที่สำคัญที่สุด:

> **ห้ามเปลี่ยน Master ถ้ายังพิสูจน์ไม่ได้ว่า state ปัจจุบัน clean และ consistent**
