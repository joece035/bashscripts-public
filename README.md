# 🚀 JOE_ENV — Personal Command Center (Public)

> Cross-platform bash/zsh ecosystem for **WSL**, **Termux (Android)**, **MuMuPlayer**, and **Git Bash**.
> Single entry point → auto-detect environment → load SSOT modules.

---

## ⚡ Quick Start (No Auth Required)

คุณสามารถโคลน Repository นี้บนเครื่องใหม่ใดๆ ได้ทันทีโดยไม่ต้องใช้ SSH Key หรือ Login:

```bash
# 1. Clone via HTTPS (Public - No auth needed)
git clone https://github.com/joece035/bashscripts-public.git ~/bashscripts
cd ~/bashscripts

# 2. ตั้งค่าไฟล์ Environment & Secrets
cp .env.example .env
chmod 600 .env
# (แก้ไขค่าคีย์ใน .env ตามต้องการ หรือปล่อยว่างไว้สำหรับฟังก์ชันพื้นฐาน)

# 3. รันตัวติดตั้ง (ตรวจจับ Termux / WSL / Git Bash อัตโนมัติ)
./bootstrap/setup.sh

# 4. Reload Shell
source ~/.bashrc   # WSL / Git Bash
source ~/.zshrc    # Termux / ZSH
```

---

## 🏗️ Architecture & SSOT (Single Source of Truth)

โครงสร้างไดเรกทอรีและโมดูลปัจจุบันตามสถาปัตยกรรม SSOT:

```
bashscripts/
├── joe.sh                    ← 🎯 MAIN ENTRY POINT (รัน ssot_load() เพื่อโหลดทุกอย่าง)
│
├── .env.example              ← Template ตัวแปรแวดล้อม (Public)
├── .env                      ← Private Secrets (Local only, ห้าม commit)
├── .bash_helper              ← ตัวช่วยเช็คความถูกต้องของการโหลดไฟล์
│
├── bootstrap/
│   ├── 00-env.sh             ← SSOT Environment Variables & Paths (อ่าน .env)
│   └── setup.sh              ← สคริปต์ติดตั้งสำหรับเครื่องใหม่
│
├── core/
│   ├── 01-colors.sh          ← Color Engine V3 (c/cn/color/ctab/hline/rc)
│   ├── aliases.sh            ← Alias คำสั่งหลัก (cls/h/reload/merge/ฯลฯ)
│   ├── bash-manager.sh       ← File Manager CLI (fm/xfm)
│   ├── ssh-config.sh         ← SSH Keygen / Auth Helpers (cb_copy/ssh_kgen)
│   ├── ensure.sh             ← Dependency & Package auto-installer
│   ├── 3worlds.sh            ← Multi-world SSH & sync (tm/tw/wsl/push/pull)
│   ├── profiles.sh           ← จัดการ Profile AI (pf joe | pf mom)
│   └── theme.sh              ← Dynamic Shell Prompt & Border Engine
│
├── functions/                ← Modular Shell Functions
│   ├── 00-fm-loader.sh       ← File Manager bootstrapper
│   ├── 00.1-function-tools.sh← Utility helpers (mth/backup/ฯลฯ)
│   ├── 02-systems.sh         ← System tools (kp/fpk/adb/scrcpy)
│   ├── 03-fpath.sh           ← Fast Directory Navigation (fn/ep/hop/sd)
│   ├── 04-openclaw.sh        ← OpenClaw automation integration
│   ├── 05-pathx.sh           ← Path & Explorer tools
│   ├── 05-project.sh         ← Project Runners
│   ├── 07-wtf.sh             ← System diagnostics
│   ├── 08-nexus.sh           ← Nexus vault integration
│   ├── 10-ai.sh              ← AI CLI integration
│   ├── 12-git.sh             ← Git workflow shortcuts
│   │
│   └── joe-block/            ← 📊 Block Engine V4 (Canonical)
│       ├── entry.sh          ← Entry point (m/dashboard)
│       ├── styles/           ← Block styles & symbols
│       └── components/       ← UI components
│
├── tools/                    ← Standalone Executable Tools
│   ├── syncctl/syncctl       ← 🔄 Syncthing Cluster Controller (Canonical)
│   ├── safe-edit.sh          ← Pre-commit guard (ANSI/drift check)
│   ├── ssot-audit.sh         ← SSOT compliance auditor
│   └── hermes.sh             ← Hermes CLI wrapper
│
├── profiles/                 ← Configuration Templates
│   ├── wsl/.zshrc / .bashrc
│   ├── termux/.zshrc
│   ├── oppo/.zshrc
│   └── git-bash/.bashrc
│
├── AGENT.md                  ← AI Agent Architecture & Protocol Rules
└── DEPENDENCY_MAP.md         ← Module Graph & Dependency Mapping
```

---

## 🧭 ระบบ Path Variables (SSOT System)

| ตัวแปร (Canonical) | ความหมาย | สภาพแวดล้อมที่รองรับ |
|-------------------|----------|-------------------|
| `$SSOT`           | Root path ของ repo (`~/bashscripts`) | ทุก Platform |
| `$SCRIPTS_PATH`   | Alias ชี้ไปที่ `$SSOT` | ทุก Platform |
| `$COLOR_PATH`     | ชี้ไปที่ `$SSOT/core/01-colors.sh` | ทุก Platform |
| `$hpc`            | Path ฝั่ง Windows (`/mnt/c/Users/User`) | WSL, Git Bash |
| `$hwsl`           | Path ฝั่ง WSL | WSL, Git Bash |

*(หมายเหตุ: ตัวแปรเก่า `$JOE_ROOT`, `$JOE_CORE`, `$JOE_PLUGINS` ยังคงมี Fallback รองรับเพื่อ Backward Compatibility)*

---

## 🌐 การตรวจจับสภาพแวดล้อม (`JOE_ENV`)

`joe.sh` จะระบุสภาพแวดล้อมอัตโนมัติเมื่อเปิดเทอร์มินัล:

| `JOE_ENV` | แพลตฟอร์ม | เชลล์ | รายละเอียด |
|-----------|-----------|------|------------|
| `WSL` | Windows Subsystem for Linux | bash / zsh | Linux บน Windows |
| `TERMUX` | Android (Termux) | zsh | อุปกรณ์พกพา |
| `MUMU` | MuMuPlayer Emulator | zsh | Android จำลองบน PC |
| `GIT-BASH`| Git Bash on Windows | bash | Bash บน Windows โดยตรง |

---

## 🔐 นโยบายความปลอดภัยและ Secrets (Zero-Leak)

- **ห้าม Commit Secrets:** ไฟล์ `.env` ที่เก็บ Token/Key จะถูกบล็อกด้วย `.gitignore` เสมอ
- **Template พร้อมใช้:** ใช้ `.env.example` เป็นโครงสร้างตั้งต้นสำหรับทุกเครื่องใหม่
- **Dynamic Load:** `bootstrap/00-env.sh` จะโหลดค่าจาก `.env` ภายในเครื่องแบบ Dynamic หากไม่มีไฟล์ ค่าเริ่มต้นจะเป็นสตริงว่างเพื่อความปลอดภัยสูงสุด

---

## 📄 ใบอนุญาต (License)

Distributed under the MIT License.