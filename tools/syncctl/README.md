# 🛡️ `syncctl` — Syncthing Ownership Controller

> **Single source of truth for Syncthing cluster ownership.**
> ทำให้มี **Master ได้แค่เครื่องเดียว** เครื่องอื่นเป็น `receiveonly` เท่านั้น → ไม่มี conflict จากการเขียนพร้อมกัน

สร้างขึ้นเพื่อแก้ปัญหา:
- แก้ไฟล์บนเครื่องหนึ่ง → Syncthing revert กลับเป็นเวอร์ชันเก่าจากเครื่องอื่น
- `.sync-conflict-*` เต็มไปหมด เพราะทุกเครื่องเป็น `sendreceive` พร้อมกัน
- Master ไม่ชัดเจน → "ตกลงกันไม่ได้ว่าใครแก้"

---

## 📚 เอกสาร

| ไฟล์ | สำหรับ |
|------|--------|
| **`README.md`** (ไฟล์นี้) | Quick start + setup + features |
| `~/bashscripts/syncthing_control.md` | Full design spec (22 sections + 23-25 design decisions) |
| `~/bashscripts/tools/syncctl/lib/*.sh` | Source code (modular, each file has header comment) |
| `~/bashscripts/tools/syncctl/tests/run.sh` | Test suite (30 assertions) |

---

## ✨ Features

### 1. **Single Master, enforced**
- มี Master ได้แค่เครื่องเดียวเท่านั้น → เครื่องนั้น `sendonly`
- เครื่องอื่นทั้งหมดต้องเป็น `receiveonly`
- `sendreceive` บน folder ที่ control ถือว่า **ผิดหลัก** → `syncctl doctor` จะเตือน

### 2. **Mandatory Checkpoint ก่อนทุก handover**
- 4 check: local state + cluster sync + conflicts + folder types
- ถ้า checkpoint fail → transfer abort ทันที
- ไม่มี "looks good" → มี checkpoint file + audit log

### 3. **Safe Handover (two-phase commit)**
- Promote target → confirm → demote old master
- ถ้า crash ระหว่างนี้ → `state.json` + `syncctl recover` กู้คืนได้

### 4. **Break-glass: `syncctl transfer --force`**
- สำหรับกรณี Master ตาย (offline นาน)
- ต้องระบุ `--reason` + พิมพ์ `"FORCE TRANSFER"` confirm
- บันทึก audit log

### 5. **Dry-run ทุก command ที่เปลี่ยน state**
```bash
syncctl transfer windows --dry-run
# แสดงสิ่งที่จะเกิดขึ้นโดยไม่แตะอะไร
```

### 6. **Idempotent**
- `transfer` ไปเครื่องเดิม → "already MASTER" ไม่ทำอะไร
- `lock` ซ้ำ → บอกว่า "already locked"

### 7. **Conflict resolution**
- `syncctl conflicts` — list `.sync-conflict-*` ทั้งหมด
- `syncctl resolve <file> --keep newer|master` — archive + remove

### 8. **Mock-based testing**
- ไม่ต้องมี cluster จริงในการ test
- 30 tests ครอบคลุม: status, checkpoint, transfer, lock, reconcile, doctor
- Run: `bash tools/syncctl/tests/run.sh`

### 9. **SSOT-native**
- Reuses `00-env.sh` (NODE_*_ST_ID, ST_KEY_*, ST_URL_*)
- ไม่มี YAML แยก, ไม่มี secrets ใน repo
- Device registry = associative arrays populate จาก env

### 10. **CRLF-safe (bonus)**
- ไม่ต้องกังวล CRLF จากเครื่องอื่นแล้ว (joe.sh มี self-heal guard แล้ว)
- `syncctl doctor` ตรวจ CRLF ในทุกไฟล์ .sh

---

## 🏗️ Architecture (1 minute)

```text
syncctl (CLI)
    │
    └── dispatches to:
          ├── status / who        → read state + render
          ├── checkpoint          → 4 checks + write #N
          ├── transfer            → two-phase commit
          ├── init                → first-time master setup
          ├── lock / unlock       → mkdir-based atomic lock
          ├── conflicts / resolve → local FS
          ├── doctor              → 7-step audit
          ├── recover             → stale handover menu
          └── logs                → tail audit log
```

```
syncctl/lib/
├── config.sh       ─ paths + device registry (reuses 00-env.sh)
├── api.sh          ─ Syncthing REST client (curl, mockable)
├── mock.sh         ─ test override for api_call
├── state.sh        ─ master cache + state.json + audit
├── lock.sh         ─ mkdir-based atomic lock
├── checkpoint.sh   ─ 4-check validator
├── ownership.sh    ─ folder type changes
├── handover.sh     ─ two-phase commit + recovery
├── renderer.sh     ─ pretty output
└── doctor.sh       ─ audit
```

**Invariants (must always hold):**
1. Master = `sendonly`, อื่น = `receiveonly`
2. `.syncctl/master` (synced) = local cache
3. 0 `.sync-conflict-*` files during checkpoint
4. `state.json.handover_in_progress == false` (unless recovery)

---

## 🚀 Quick Start

### บนเครื่อง Master (เครื่องแรกที่ setup)

```bash
# 1. ตรวจว่า 00-env.sh มี NODE_*_ST_ID ครบทุกเครื่อง
grep "NODE_.*_ST_ID=" ~/bashscripts/00-env.sh

# 2. Init WSL เป็น Master แรก
syncctl init wsl

# 3. ตรวจสถานะ
syncctl status
```

Output ควรเป็น:

```text
╭────────────────────────────────────────────╮
│ SYNC CONTROL                               │
├────────────────────────────────────────────┤
│ MASTER                                     │
│   ● wsl                                    │
├────────────────────────────────────────────┤
│ DEVICES                                    │
│   wsl      sendonly       ✓ MASTER        │
│   windows  receiveonly    ✓ SYNCED         │
│   termux   receiveonly    ✓ SYNCED         │
│   mumu     receiveonly    ✓ SYNCED         │
├────────────────────────────────────────────┤
│ CHECKPOINT                                 │
│   #0001 ✓ CLEAN                            │
╰────────────────────────────────────────────╯
```

### บนเครื่องอื่น (Windows / Termux / MuMu)

**ไม่ต้อง setup อะไรเพิ่ม** — แค่ source `joe.sh` ตามปกติ + รอให้ Syncthing sync `.syncctl/master` มา

```bash
# บน Windows / Termux / MuMu
syncctl status    # แสดง master เดียวกัน (wsl)
syncctl who       # → "MASTER: wsl"
```

---

## 📋 Commands

| Command | ใช้ทำอะไร |
|---------|-----------|
| `syncctl status` | แสดง master + ทุก device + folder type + checkpoint ล่าสุด |
| `syncctl who` | แสดง master (text only) |
| `syncctl checkpoint` | รัน 4 check + สร้าง checkpoint #N |
| `syncctl transfer <dev>` | Safe handover |
| `syncctl transfer <dev> --dry-run` | Preview โดยไม่เปลี่ยน state |
| `syncctl transfer <dev> --force --reason "..."` | Break-glass (master offline) |
| `syncctl init <dev>` | First-time setup |
| `syncctl lock` / `unlock` | Manual lock (manual sync pause) |
| `syncctl conflicts` | List `.sync-conflict-*` |
| `syncctl resolve <file> --keep newer\|master` | เลือก winner + archive |
| `syncctl recover` | Recover from stale handover |
| `syncctl doctor` | รัน 7-step audit (CRLF, master, conflicts, types, lock, API, stale) |
| `syncctl logs [N]` | ดู audit log (NDJSON) |
| `syncctl fix-types [--dry-run]` | Reconcile folder types with master (idempotent) |
| `syncctl set-type <dev> <type>` | Set one device folder type (escape hatch) |
| `syncctl types` | Show ownership table (current vs expected) |
| `syncctl --debug <cmd>` | Verbose logging |

---

## 🔧 Setup บนอุปกรณ์อื่น (Windows / Termux / MuMu)

### ข่าวดี: **แทบไม่ต้องทำอะไร**

`syncctl` ถูก sync ข้ามเครื่องผ่าน Syncthing อัตโนมัติเพราะ:
1. **Tool files** อยู่ใน `~/bashscripts/tools/syncctl/` → Syncthing folder
2. **`.syncctl/master`** ถูก sync ข้ามเครื่อง → ทุกเครื่องรู้ว่าใครเป็น Master
3. **Node registry** (`NODE_*_ST_ID`, `ST_KEY_*`) มาจาก `00-env.sh` ซึ่งแต่ละเครื่องมีของตัวเอง

### สิ่งที่ต้องทำ

#### 1. ตรวจว่า `00-env.sh` มี device IDs ครบ

**ทุกเครื่องต้องมี `NODE_<EACH>_ST_ID` ของเครื่องอื่นด้วย** (ไม่ใช่แค่ของตัวเอง) เพราะ `syncctl` ใช้ map ชื่อ → device ID

```bash
# ควรเห็นครบทั้ง 4 เครื่อง
grep "NODE_.*_ST_ID=" ~/bashscripts/00-env.sh
```

#### 2. ตรวจว่า ST API URL + key มี

```bash
grep "ST_KEY_\|ST_URL_" ~/bashscripts/00-env.sh
```

ควรเห็น:
```
ST_KEY_WSL=...
ST_KEY_WIN=...
ST_KEY_TERMUX=...
ST_KEY_MUMU=...
URL_WSL=...
URL_WIN=...
URL_TERMUX=...
URL_MUMU=...
```

#### 3. Test การเชื่อมต่อ

```bash
syncctl doctor
```

ถ้าเห็น `OK v1.27.7` ทุกเครื่อง = พร้อมใช้
ถ้าเห็น `UNREACHABLE` → ตรวจ SSH, Tailscale, firewall

#### 4. ถ้าใช้ Termux (Android)

Termux จะ source `joe.sh` ตามปกติ → `syncctl` พร้อมใช้
- ตรวจ `JOE_ENV="TERMUX"` ใน `~/.env`
- API URL ของ Termux ต้องเข้าถึงได้จากเครื่องอื่น (ผ่าน Tailscale/MagicDNS)

---

## 🧪 การ Test

```bash
# รัน test suite (ไม่ต้องมี cluster จริง)
bash ~/bashscripts/tools/syncctl/tests/run.sh
```

Output:
```text
═══════════════════════════════════════════════════════════
  syncctl test suite
═══════════════════════════════════════════════════════════

TEST: status (clean cluster, WSL master)
  ✓ shows wsl as master
  ✓ shows MASTER role
  ✓ shows folder type sendonly
  ✓ shows checkpoint section
...
  All 30 tests passed ✓
```

**Tests ครอบคลุม:**
- status / who
- checkpoint pass + fail
- transfer dry-run
- transfer idempotency
- full transfer (wsl → windows)
- lock concurrency
- state reconcile (local vs synced)
- doctor

---

## 🚨 Safety Rules

### DO ✅
- รัน `syncctl doctor` เป็น habit ทุกครั้งหลัง pull
- ใช้ `--dry-run` ก่อน transfer จริง
- ระบุ `--reason` ทุกครั้งที่ force
- เช็ค `syncctl status` ก่อนแก้ไฟล์สำคัญ
- ใช้ `syncctl conflicts` + `resolve` ทันทีที่เจอ

### DON'T ❌
- อย่าแก้ `config.xml` ของ Syncthing โดยตรง (ใช้ API เท่านั้น)
- อย่าใช้ `--force` ตอน Master online
- อย่า kill `syncctl transfer` กลางทาง (ถ้าจำเป็น → `syncctl recover`)
- อย่าแก้ไฟล์บนเครื่องที่ไม่ใช่ Master (ใช้ `syncctl transfer` ก่อน)

---

## 🛠️ Troubleshooting

### `syncctl: no API URL for device 'xxx'`

→ `00-env.sh` ไม่มี `NODE_xxx_ST_URL` หรือ `ST_KEY_xxx`
→ เพิ่มเข้าไป แล้ว source ใหม่

### `UNREACHABLE` ใน doctor

→ API port (8383-8386) ของเครื่องนั้นไม่เปิด หรือ firewall block
→ ตรวจ `curl http://termux:8383/rest/system/version -H "X-API-Key: ..."`

### `Checkpoint FAIL: out of sync`

→ มีเครื่องที่ยัง sync ไม่ครบ (pending > 0)
→ รอให้ sync เสร็จก่อน retry
→ ดูสถานะ: `syncctl status`

### `Checkpoint FAIL: API-reported conflicts`

→ Syncthing API แจ้งว่ามี error ใน folder นั้น
→ `syncctl conflicts` + `syncctl resolve <file>`

### `STALE HANDOVER DETECTED`

→ `syncctl transfer` ค้างกลางทาง (timeout, network drop, kill)
→ รัน `syncctl recover` → เลือก ABORT/CONTINUE/STATUS

### CRLF warnings จาก Acode-X (มือถือ)

→ แก้ด้วย self-heal ใน `joe.sh` (auto-fix ตอน shell เปิด)
→ หรือ `sed -i 's/\r$//' <file>` manual

---

## 📂 File Locations

| Path | Sync? | Purpose |
|------|-------|---------|
| `~/bashscripts/tools/syncctl/` | ✅ Yes (Syncthing) | Source code |
| `~/bashscripts/.syncctl/master` | ✅ Yes (Syncthing) | SSOT for master pointer |
| `~/.local/share/syncctl/master` | ❌ Local | Master cache |
| `~/.local/share/syncctl/state.json` | ❌ Local | Handover state |
| `~/.local/share/syncctl/audit.log` | ❌ Local | NDJSON event log |
| `~/.local/share/syncctl/checkpoints/` | ❌ Local | Per-checkpoint JSON |
| `~/.local/share/syncctl/conflicts/` | ❌ Local | Archived losers |
| `~/bashscripts/00-env.sh` | ✅ Yes | Node registry (SSOT) |

---

## 🤝 Integration กับ Tools อื่น

### `joe.sh` (recommended)
- `joe.sh` ไม่ load `syncctl` อัตโนมัติ (เพราะ `syncctl` เป็น utility ไม่ใช่ core)
- ใส่ alias ใน `02-aliases.sh`:
```bash
alias sc='syncctl'
alias sctl='syncctl'
```

### `tools/safe-edit.sh`
- (TODO) `safe-edit` จะตรวจ `syncctl who` ก่อนอนุญาตแก้ไฟล์

### `tools/ssot-audit.sh`
- รัน `syncctl doctor` + `ssot-audit` พร้อมกันเป็น nightly check

---

## 🎯 TL;DR

```bash
# เครื่อง Master (WSL):
syncctl init wsl

# เครื่องอื่น:
syncctl status         # ดูว่าใครเป็น Master
syncctl doctor         # audit
syncctl transfer wsl   # กลับมาเป็น Master (ถ้าต้องการ)

# Workflow ปกติ:
syncctl checkpoint     # ก่อนย้าย
syncctl transfer win --dry-run
syncctl transfer win --reason "fix sshd"
```

**หลักการ:** *If uncertain, do not change ownership.*
*Checkpoints exist to make certainty possible.*

---

## 🔧 Folder Type Reconciliation

### ปัญหา: `syncctl doctor` แจ้ง folder type ผิด

เช่น `master=wsl` แต่ `termux` เป็น `sendreceive` แทนที่จะเป็น `receiveonly`
→ เกิดจากตอน onboard device ใหม่ ลืม set type ให้ถูก

### วิธีแก้: ใช้ `syncctl fix-types`

```bash
# 1. ดูก่อนว่า device ไหน type ผิด
syncctl types
# DEVICE     CURRENT        EXPECTED       STATUS
# wsl        sendonly       sendonly       ✓ ok (MASTER)
# windows    sendreceive    receiveonly    ✗ MISMATCH (REPLICA)
# termux     receiveonly    receiveonly    ✓ ok (REPLICA)
# mumu       sendreceive    receiveonly    ✗ MISMATCH (REPLICA)

# 2. Preview การแก้ (ไม่แตะ API)
syncctl fix-types --dry-run

# 3. รันจริง — set ทุก device ให้ตรงกับ master
syncctl fix-types --reason "reconcile after termux reinstall"
```

### คุณสมบัติ:

- **Idempotent** — รันซ้ำได้, ไม่ error ถ้าทุก device ถูกอยู่แล้ว
- **No state.json change** — ไม่ใช่ handover, master pointer ไม่เปลี่ยน
- **Locked** — ใช้ lock เดิม → กัน race กับ `transfer` ที่อาจรันพร้อมกัน
- **Safe default** — ไม่แตะ API ถ้าไม่ต้องเปลี่ยน (device ที่ถูกอยู่แล้วถูก skip)
- **Audited** — บันทึกใน `audit.log` ทุกครั้ง

### เมื่อไหร่ควรใช้อะไร:

| ต้องการ | ใช้ | เพราะ |
|---------|-----|-------|
| แก้เฉพาะ 1 device | `syncctl set-type <dev> <type>` | Escape hatch สำหรับ edge case |
| แก้ทั้ง cluster ให้ตรงกับ master | `syncctl fix-types` | Auto-reconcile ตาม master pointer |
| เปลี่ยน master ไปเครื่องอื่น | `syncctl transfer` | Two-phase commit + state.json |
| ดูสถานะตอนนี้ | `syncctl types` หรือ `syncctl status` | Read-only |
