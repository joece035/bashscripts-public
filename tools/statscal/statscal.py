#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
🚀 STATSCAL (Win Rate Statistics Calculator & Long-Term History TUI)
==============================================================================
Parity with: https://statscal-by-joez.netlify.app/
Storage: SQLite persistent database (supporting years of calculations)
Platform: WSL, Termux, Linux, macOS, Windows (Python standard library only)
==============================================================================
"""

import sys
import os
import math
import sqlite3
import datetime
import json
import csv
import argparse
import curses

# ==============================================================================
# CONFIG & I18N
# ==============================================================================

APP_VERSION = "2.0.0"
APP_TITLE = "Win Rate Statistics Calculator"
AUTHOR_FOOTER = "For everyone ❤️ BY .7oEz & Antigravity"

def get_db_path():
    """Determine SSOT/XDG compliant database path."""
    data_home = os.environ.get("XDG_DATA_HOME")
    if not data_home:
        data_home = os.path.expanduser("~/.local/share")
    db_dir = os.path.join(data_home, "statscal")
    os.makedirs(db_dir, exist_ok=True)
    return os.path.join(db_dir, "history.db")

TEXT = {
    "th": {
        "title": "Statistics Calculator (เครื่องคำนวณ Win Rate)",
        "tabs": [
            "1. WR% ปัจจุบัน",
            "2. ชนะกี่ครั้ง WR% จะขึ้น",
            "3. แพ้กี่ครั้ง WR% จะลง",
            "4. ประวัติ (History)",
            "5. สถิติ & แนวโน้ม",
            "6. ช่วยเหลือ & ตั้งค่า",
        ],
        "modes": {
            "calculate_rate": "WR% ปัจจุบัน",
            "find_win": "ชนะกี่ครั้ง WR% จะเพิ่ม",
            "find_lose": "แพ้กี่ครั้ง WR% จะลด",
            "history": "History",
        },
        "labels": {
            "wins": "จำนวนการชนะ (Wins):",
            "losses": "จำนวนการแพ้ (Losses):",
            "target": "Target WR% (เป้าหมาย):",
            "totalMatches": "จำนวนเกมทั้งหมด:",
            "currentRate": "อัตราการชนะปัจจุบัน:",
            "targetRate": "อัตราการชนะที่กำลังจะขึ้นไป:",
            "targetRateLose": "อัตราการชนะที่กำลังจะลง:",
            "winToAdd": "ต้องชนะติดต่อกันอีก (ห้ามแพ้เลย):",
            "loseToAdd": "แพ้ติดต่อกันได้สูงสุด (โดย WR% ไม่ลด):",
            "note": "บันทึกช่วยจำ (Note):",
            "filter": "ช่วงเวลา:",
            "page": "หน้า:",
            "totalRecords": "รายการทั้งหมด:",
            "search": "ค้นหา (Search):",
        },
        "filters": {
            "all": "ทั้งหมด (All Time)",
            "1y": "1 ปีล่าสุด (Past 1 Year)",
            "6m": "6 เดือนล่าสุด (Past 6 Months)",
            "30d": "30 วันล่าสุด (Past 30 Days)",
            "7d": "7 วันล่าสุด (Past 7 Days)",
            "today": "วันนี้ (Today)",
        },
        "buttons": {
            "calculate": " [ Enter / C ] คำนวณ & บันทึก ",
            "clear": " [ Esc ] ล้างข้อมูล ",
            "switchLang": " [ L ] ภาษา (TH/EN) ",
            "delete": " [ D ] ลบรายการ ",
            "export": " [ E ] Export (CSV/JSON) ",
            "quit": " [ Q ] ออก ",
        },
        "messages": {
            "saved": "✓ บันทึกลงประวัติสำเร็จ!",
            "deleted": "✓ ลบรายการสำเร็จ",
            "cleared_all": "✓ ล้างประวัติทั้งหมดแล้ว",
            "exported": "✓ ส่งออกข้อมูลสำเร็จ:",
            "invalid_num": "กรุณากรอกตัวเลขจำนวนเต็มบวกที่ถูกต้อง",
            "zero_games": "จำนวนเกมรวมต้องมากกว่า 0",
            "no_history": "ไม่มีข้อมูลประวัติในช่วงเวลานี้",
        },
        "footer": AUTHOR_FOOTER
    },
    "en": {
        "title": "Statistics Calculator (Win Rate Engine)",
        "tabs": [
            "1. Current WR%",
            "2. Wins to Reach Target",
            "3. Losses before Drop",
            "4. History",
            "5. Stats & Trends",
            "6. Help & Settings",
        ],
        "modes": {
            "calculate_rate": "CALCULATE WR%",
            "find_win": "Find wins to up WR%",
            "find_lose": "Find losses to down WR%",
            "history": "HISTORY",
        },
        "labels": {
            "wins": "Total Wins (W):",
            "losses": "Total Losses (L):",
            "target": "Target WR%:",
            "totalMatches": "Total Matches:",
            "currentRate": "Current Win Rate:",
            "targetRate": "Next Target Win Rate:",
            "targetRateLose": "Next Target Win Rate (down):",
            "winToAdd": "Wins needed without any loss:",
            "loseToAdd": "Max losses allowed without drop:",
            "note": "Note/Tag:",
            "filter": "Timeframe:",
            "page": "Page:",
            "totalRecords": "Total Records:",
            "search": "Search:",
        },
        "filters": {
            "all": "All Time",
            "1y": "Past 1 Year",
            "6m": "Past 6 Months",
            "30d": "Past 30 Days",
            "7d": "Past 7 Days",
            "today": "Today",
        },
        "buttons": {
            "calculate": " [ Enter / C ] Calculate & Save ",
            "clear": " [ Esc ] Clear ",
            "switchLang": " [ L ] Language (TH/EN) ",
            "delete": " [ D ] Delete Record ",
            "export": " [ E ] Export (CSV/JSON) ",
            "quit": " [ Q ] Quit ",
        },
        "messages": {
            "saved": "✓ Saved to history!",
            "deleted": "✓ Record deleted",
            "cleared_all": "✓ All history cleared",
            "exported": "✓ Data exported successfully:",
            "invalid_num": "Please enter valid positive numbers",
            "zero_games": "Total games (Wins + Losses) must be > 0",
            "no_history": "No history records found in this timeframe",
        },
        "footer": AUTHOR_FOOTER
    }
}

# ==============================================================================
# DATABASE MANAGER (1-YEAR+ SCALABLE STORAGE)
# ==============================================================================

class HistoryDB:
    def __init__(self, db_path=None):
        self.db_path = db_path or get_db_path()
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS calculations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    mode TEXT NOT NULL,
                    wins INTEGER NOT NULL,
                    losses INTEGER NOT NULL,
                    total_games INTEGER NOT NULL,
                    raw_rate REAL NOT NULL,
                    target_rate REAL,
                    win_to_add INTEGER,
                    lose_to_add INTEGER,
                    note TEXT DEFAULT ''
                )
            """)
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_timestamp ON calculations(timestamp)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_mode ON calculations(mode)")
            
            # App settings table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                )
            """)
            conn.commit()

    def get_setting(self, key, default=None):
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT value FROM settings WHERE key = ?", (key,))
            row = cursor.fetchone()
            return row[0] if row else default

    def set_setting(self, key, value):
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)", (key, str(value)))
            conn.commit()

    def insert_record(self, mode, wins, losses, raw_rate, target_rate=None, win_to_add=None, lose_to_add=None, note=""):
        total = wins + losses
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO calculations (
                    timestamp, mode, wins, losses, total_games,
                    raw_rate, target_rate, win_to_add, lose_to_add, note
                ) VALUES (datetime('now', 'localtime'), ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (mode, wins, losses, total, raw_rate, target_rate, win_to_add, lose_to_add, note))
            conn.commit()
            return cursor.lastrowid

    def delete_record(self, record_id):
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM calculations WHERE id = ?", (record_id,))
            conn.commit()
            return cursor.rowcount > 0

    def clear_history(self, filter_code="all"):
        time_clause = self._get_time_filter_clause(filter_code)
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(f"DELETE FROM calculations WHERE 1=1 {time_clause}")
            conn.commit()
            return cursor.rowcount

    def _get_time_filter_clause(self, filter_code):
        if filter_code == "today":
            return "AND date(timestamp) = date('now', 'localtime')"
        elif filter_code == "7d":
            return "AND timestamp >= datetime('now', '-7 days', 'localtime')"
        elif filter_code == "30d":
            return "AND timestamp >= datetime('now', '-30 days', 'localtime')"
        elif filter_code == "6m":
            return "AND timestamp >= datetime('now', '-6 months', 'localtime')"
        elif filter_code == "1y":
            return "AND timestamp >= datetime('now', '-1 year', 'localtime')"
        return ""

    def get_records(self, filter_code="all", search_query="", limit=50, offset=0):
        time_clause = self._get_time_filter_clause(filter_code)
        search_clause = ""
        params = []
        if search_query:
            search_clause = "AND (note LIKE ? OR mode LIKE ?)"
            params.extend([f"%{search_query}%", f"%{search_query}%"])

        query = f"""
            SELECT id, timestamp, mode, wins, losses, total_games,
                   raw_rate, target_rate, win_to_add, lose_to_add, note
            FROM calculations
            WHERE 1=1 {time_clause} {search_clause}
            ORDER BY timestamp DESC, id DESC
            LIMIT ? OFFSET ?
        """
        params.extend([limit, offset])

        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(query, params)
            rows = cursor.fetchall()
            return [dict(r) for r in rows]

    def count_records(self, filter_code="all", search_query=""):
        time_clause = self._get_time_filter_clause(filter_code)
        search_clause = ""
        params = []
        if search_query:
            search_clause = "AND (note LIKE ? OR mode LIKE ?)"
            params.extend([f"%{search_query}%", f"%{search_query}%"])

        query = f"SELECT COUNT(*) FROM calculations WHERE 1=1 {time_clause} {search_clause}"
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(query, params)
            return cursor.fetchone()[0]

    def get_stats_summary(self, filter_code="all"):
        time_clause = self._get_time_filter_clause(filter_code)
        query = f"""
            SELECT 
                COUNT(*) as total_calcs,
                AVG(raw_rate) as avg_rate,
                MIN(raw_rate) as min_rate,
                MAX(raw_rate) as max_rate,
                SUM(wins) as sum_wins,
                SUM(losses) as sum_losses,
                SUM(total_games) as sum_games
            FROM calculations
            WHERE 1=1 {time_clause}
        """
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(query)
            row = cursor.fetchone()
            return dict(row) if row else {}

    def get_trend_data(self, filter_code="all", max_points=20):
        time_clause = self._get_time_filter_clause(filter_code)
        query = f"""
            SELECT id, timestamp, raw_rate, wins, losses
            FROM calculations
            WHERE 1=1 {time_clause}
            ORDER BY timestamp ASC, id ASC
        """
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(query)
            rows = cursor.fetchall()
            data = [dict(r) for r in rows]
            if len(data) <= max_points:
                return data
            step = len(data) / max_points
            return [data[int(i * step)] for i in range(max_points)]

    def export_data(self, filepath, fmt="csv", filter_code="all"):
        records = self.get_records(filter_code=filter_code, limit=100000, offset=0)
        if fmt == "json":
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(records, f, indent=2, ensure_ascii=False)
        else:
            if not records:
                return 0
            with open(filepath, "w", newline="", encoding="utf-8-sig") as f:
                writer = csv.DictWriter(f, fieldnames=records[0].keys())
                writer.writeheader()
                writer.writerows(records)
        return len(records)

# ==============================================================================
# CALCULATION CORE MATH
# ==============================================================================

def calc_win_rate(wins, losses):
    total = wins + losses
    if total <= 0:
        return 0.0, 0
    raw = (100.0 * wins) / total
    return raw, total

def calc_find_win(wins, losses, target=None):
    raw, total = calc_win_rate(wins, losses)
    if target is None:
        target = math.floor(raw) + 1.0
    
    if target >= 100.0:
        win_to_add = "∞"
    else:
        required = (target * losses) / (100.0 - target)
        win_to_add = max(0, math.ceil(required - wins))
    return raw, target, win_to_add

def calc_find_lose(wins, losses, target=None):
    raw, total = calc_win_rate(wins, losses)
    if target is None:
        target = float(math.floor(raw))
    
    if target <= 0.0:
        lose_to_add = "∞"
    else:
        max_losses = (wins * (100.0 - target) - target * losses) / target
        lose_to_add = max(0, math.floor(max_losses))
    return raw, target, lose_to_add

# ==============================================================================
# TERMINAL UI (CURSES ENGINE)
# ==============================================================================

class StatscalTUI:
    def __init__(self, stdscr):
        self.stdscr = stdscr
        self.db = HistoryDB()
        
        self.lang = self.db.get_setting("lang", "en")
        if self.lang not in TEXT:
            self.lang = "en"
            
        self.active_tab = 0
        self.wins_str = "100"
        self.losses_str = "50"
        self.custom_target_str = ""
        self.note_str = ""
        self.active_field = 0
        
        self.calc_results = None
        self.status_msg = ""
        self.status_time = 0
        
        self.hist_filter_idx = 0
        self.hist_filters = ["all", "1y", "6m", "30d", "7d", "today"]
        self.hist_page = 0
        self.hist_page_size = 10
        self.hist_selected_idx = 0
        self.hist_search_query = ""

        self._init_colors()
        self._recompute_preview()

    def _init_colors(self):
        curses.start_color()
        curses.use_default_colors()
        curses.curs_set(0)
        self.stdscr.nodelay(False)
        self.stdscr.keypad(True)
        try:
            curses.init_pair(1, curses.COLOR_CYAN, -1)
            curses.init_pair(2, curses.COLOR_YELLOW, -1)
            curses.init_pair(3, curses.COLOR_GREEN, -1)
            curses.init_pair(4, curses.COLOR_RED, -1)
            curses.init_pair(5, curses.COLOR_WHITE, curses.COLOR_BLUE)
            curses.init_pair(6, curses.COLOR_WHITE, curses.COLOR_BLACK)
            curses.init_pair(7, curses.COLOR_MAGENTA, -1)
            curses.init_pair(8, curses.COLOR_BLACK, curses.COLOR_CYAN)
        except Exception:
            pass

    def t(self):
        return TEXT[self.lang]

    def _recompute_preview(self):
        try:
            w = float(self.wins_str) if self.wins_str else 0.0
            l = float(self.losses_str) if self.losses_str else 0.0
            if w + l == 0:
                self.calc_results = None
                return
            
            raw, total = calc_win_rate(w, l)
            target = float(self.custom_target_str) if self.custom_target_str else None
            
            _, target_win, win_add = calc_find_win(w, l, target)
            _, target_lose, lose_add = calc_find_lose(w, l, target)
            
            self.calc_results = {
                "wins": int(w),
                "losses": int(l),
                "total": int(total),
                "raw_rate": raw,
                "target_win": target_win,
                "win_add": win_add,
                "target_lose": target_lose,
                "lose_add": lose_add,
            }
        except ValueError:
            self.calc_results = None

    def set_status(self, msg):
        self.status_msg = msg
        self.status_time = datetime.datetime.now().timestamp()

    def run(self):
        while True:
            self.stdscr.clear()
            h, w = self.stdscr.getmaxyx()
            
            if h < 20 or w < 65:
                self.stdscr.addstr(0, 0, f"Terminal size too small ({w}x{h}). Minimum required: 65x20", curses.A_BOLD)
                self.stdscr.refresh()
                key = self.stdscr.getch()
                if key in (ord('q'), ord('Q'), 27):
                    break
                continue

            self._render_header(w)
            self._render_tabs(w)
            
            if self.active_tab in (0, 1, 2):
                self._render_calculator(h, w)
            elif self.active_tab == 3:
                self._render_history(h, w)
            elif self.active_tab == 4:
                self._render_stats(h, w)
            elif self.active_tab == 5:
                self._render_help_settings(h, w)

            self._render_footer(h, w)
            self.stdscr.refresh()

            if not self._handle_input():
                break

    def _render_header(self, w):
        t = self.t()
        title_text = f" 🏆 {t['title']} v{APP_VERSION} "
        self.stdscr.attron(curses.color_pair(1) | curses.A_BOLD)
        self.stdscr.addstr(0, max(0, (w - len(title_text)) // 2), title_text)
        self.stdscr.attroff(curses.color_pair(1) | curses.A_BOLD)
        
        sub = f" [ Lang: {self.lang.upper()} ]  •  DB: {os.path.basename(self.db.db_path)}  •  {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}"
        self.stdscr.attron(curses.A_DIM)
        self.stdscr.addstr(1, max(0, (w - len(sub)) // 2), sub)
        self.stdscr.attroff(curses.A_DIM)

    def _render_tabs(self, w):
        t = self.t()
        tabs = t["tabs"]
        tab_line = 3
        
        self.stdscr.addstr(tab_line - 1, 1, "─" * (w - 2), curses.A_DIM)
        
        col = 2
        for idx, tab_name in enumerate(tabs):
            text = f" {tab_name} "
            if col + len(text) >= w - 2:
                break
            if idx == self.active_tab:
                self.stdscr.attron(curses.color_pair(5) | curses.A_BOLD)
                self.stdscr.addstr(tab_line, col, text)
                self.stdscr.attroff(curses.color_pair(5) | curses.A_BOLD)
            else:
                self.stdscr.attron(curses.A_DIM)
                self.stdscr.addstr(tab_line, col, text)
                self.stdscr.attroff(curses.A_DIM)
            col += len(text) + 1
        
        self.stdscr.addstr(tab_line + 1, 1, "─" * (w - 2), curses.A_DIM)

    def _render_calculator(self, h, w):
        t = self.t()
        start_y = 6
        left_x = 4
        
        mode_titles = [
            f"🎯 {t['modes']['calculate_rate']}",
            f"🚀 {t['modes']['find_win']}",
            f"📉 {t['modes']['find_lose']}",
        ]
        self.stdscr.attron(curses.color_pair(2) | curses.A_BOLD)
        self.stdscr.addstr(start_y - 1, left_x, f"== {mode_titles[self.active_tab]} ==")
        self.stdscr.attroff(curses.color_pair(2) | curses.A_BOLD)

        fields = [
            (t["labels"]["wins"], self.wins_str, "🏆"),
            (t["labels"]["losses"], self.losses_str, "😟"),
        ]
        if self.active_tab in (1, 2):
            default_hint = "auto"
            if self.calc_results:
                default_hint = f"auto: {self.calc_results['target_win'] if self.active_tab == 1 else self.calc_results['target_lose']}%"
            fields.append((f"{t['labels']['target']} ({default_hint})", self.custom_target_str, "🎯"))
        else:
            fields.append((t["labels"]["note"], self.note_str, "📝"))

        for i, (label, val, icon) in enumerate(fields):
            y = start_y + 1 + (i * 2)
            is_active = (self.active_field == i)
            
            self.stdscr.addstr(y, left_x, f"{icon} {label:<32}")
            
            box_x = left_x + 36
            box_width = min(24, w - box_x - 4)
            display_val = val if val else " "
            
            if is_active:
                self.stdscr.attron(curses.color_pair(8) | curses.A_BOLD)
                self.stdscr.addstr(y, box_x, f" {display_val:<{box_width - 2}} ")
                self.stdscr.attroff(curses.color_pair(8) | curses.A_BOLD)
            else:
                self.stdscr.attron(curses.A_UNDERLINE)
                self.stdscr.addstr(y, box_x, f" {display_val:<{box_width - 2}} ")
                self.stdscr.attroff(curses.A_UNDERLINE)

        card_y = start_y + 1 + (len(fields) * 2) + 1
        card_width = min(60, w - 8)
        
        self.stdscr.addstr(card_y, left_x, "┌" + "─" * (card_width - 2) + "┐", curses.A_DIM)
        for row in range(1, 6):
            self.stdscr.addstr(card_y + row, left_x, "│" + " " * (card_width - 2) + "│", curses.A_DIM)
        self.stdscr.addstr(card_y + 6, left_x, "└" + "─" * (card_width - 2) + "┘", curses.A_DIM)

        if self.calc_results:
            res = self.calc_results
            self.stdscr.attron(curses.A_BOLD)
            self.stdscr.addstr(card_y + 1, left_x + 3, f"🎮 {t['labels']['totalMatches']} {res['total']}  (W: {res['wins']} | L: {res['losses']})")
            self.stdscr.attroff(curses.A_BOLD)
            
            wr_str = f"🎯 {t['labels']['currentRate']} {res['raw_rate']:.2f}%  ({res['raw_rate']:.4f}%)"
            self.stdscr.attron(curses.color_pair(1) | curses.A_BOLD)
            self.stdscr.addstr(card_y + 2, left_x + 3, wr_str)
            self.stdscr.attroff(curses.color_pair(1) | curses.A_BOLD)

            if self.active_tab == 0:
                self.stdscr.addstr(card_y + 4, left_x + 3, f"💡 Press [ Enter ] to save this calculation into History.", curses.A_DIM)
            elif self.active_tab == 1:
                self.stdscr.addstr(card_y + 3, left_x + 3, f"🚀 {t['labels']['targetRate']} {res['target_win']}%")
                highlight_str = f"👉 {t['labels']['winToAdd']} {res['win_add']} games"
                self.stdscr.attron(curses.color_pair(3) | curses.A_BOLD)
                self.stdscr.addstr(card_y + 4, left_x + 3, highlight_str)
                self.stdscr.attroff(curses.color_pair(3) | curses.A_BOLD)
            elif self.active_tab == 2:
                self.stdscr.addstr(card_y + 3, left_x + 3, f"📉 {t['labels']['targetRateLose']} {res['target_lose']}%")
                highlight_str = f"👉 {t['labels']['loseToAdd']} {res['lose_add']} games"
                self.stdscr.attron(curses.color_pair(4) | curses.A_BOLD)
                self.stdscr.addstr(card_y + 4, left_x + 3, highlight_str)
                self.stdscr.attroff(curses.color_pair(4) | curses.A_BOLD)
        else:
            self.stdscr.addstr(card_y + 3, left_x + 3, f"⚠️  {t['messages']['zero_games']}", curses.color_pair(2))

    def _render_history(self, h, w):
        t = self.t()
        left_x = 3
        start_y = 5
        
        current_filter = self.hist_filters[self.hist_filter_idx]
        total_records = self.db.count_records(filter_code=current_filter, search_query=self.hist_search_query)
        max_pages = max(1, math.ceil(total_records / self.hist_page_size))
        if self.hist_page >= max_pages:
            self.hist_page = max_pages - 1
            
        offset = self.hist_page * self.hist_page_size
        records = self.db.get_records(
            filter_code=current_filter,
            search_query=self.hist_search_query,
            limit=self.hist_page_size,
            offset=offset
        )

        filter_label = f"🗓️ {t['labels']['filter']} "
        self.stdscr.addstr(start_y, left_x, filter_label, curses.A_BOLD)
        filter_x = left_x + len(filter_label)
        
        for idx, f_code in enumerate(self.hist_filters):
            f_text = f" [{t['filters'][f_code]}] "
            if idx == self.hist_filter_idx:
                self.stdscr.attron(curses.color_pair(5) | curses.A_BOLD)
                self.stdscr.addstr(start_y, filter_x, f_text)
                self.stdscr.attroff(curses.color_pair(5) | curses.A_BOLD)
            else:
                self.stdscr.attron(curses.A_DIM)
                self.stdscr.addstr(start_y, filter_x, f_text)
                self.stdscr.attroff(curses.A_DIM)
            filter_x += len(f_text) + 1

        table_y = start_y + 2
        header = f" {'ID':<4} {'Date/Time':<17} {'Mode':<14} {'W/L/Total':<14} {'WR%':<10} {'Target/Result':<20} "
        self.stdscr.attron(curses.color_pair(8) | curses.A_BOLD)
        self.stdscr.addstr(table_y, left_x, header[:w - 6])
        self.stdscr.attroff(curses.color_pair(8) | curses.A_BOLD)

        row_y = table_y + 1
        if not records:
            self.stdscr.addstr(row_y + 2, left_x + 4, f"ℹ️  {t['messages']['no_history']}", curses.A_DIM)
        else:
            for idx, r in enumerate(records):
                if row_y >= h - 4:
                    break
                is_selected = (idx == self.hist_selected_idx)
                
                mode_str = r['mode']
                if mode_str == 'calculate_rate':
                    mode_display = "🎯 WR%"
                elif mode_str == 'find_win':
                    mode_display = "🚀 Find Win"
                else:
                    mode_display = "📉 Find Lose"
                
                wl_str = f"{r['wins']}/{r['losses']} ({r['total_games']})"
                wr_str = f"{r['raw_rate']:.2f}%"
                
                res_str = ""
                if r['mode'] == 'find_win':
                    res_str = f"→ {r['target_rate']}% (+{r['win_to_add']} win)"
                elif r['mode'] == 'find_lose':
                    res_str = f"→ {r['target_rate']}% (-{r['lose_to_add']} lose)"
                elif r['note']:
                    res_str = f"Note: {r['note'][:15]}"

                date_str = str(r['timestamp'])[:16]
                row_str = f" {r['id']:<4} {date_str:<17} {mode_display:<14} {wl_str:<14} {wr_str:<10} {res_str:<20} "
                
                if is_selected:
                    self.stdscr.attron(curses.color_pair(5) | curses.A_BOLD)
                    self.stdscr.addstr(row_y, left_x, row_str[:w - 6])
                    self.stdscr.attroff(curses.color_pair(5) | curses.A_BOLD)
                else:
                    self.stdscr.addstr(row_y, left_x, row_str[:w - 6])
                row_y += 1

        info_y = h - 4
        page_info = f"📄 {t['labels']['page']} {self.hist_page + 1}/{max_pages}  |  {t['labels']['totalRecords']} {total_records}  |  [F] Filter  [N/P] Page  [D] Delete  [E] Export"
        self.stdscr.attron(curses.A_DIM)
        self.stdscr.addstr(info_y, left_x, page_info[:w - 6])
        self.stdscr.attroff(curses.A_DIM)

    def _render_stats(self, h, w):
        t = self.t()
        left_x = 4
        start_y = 5
        
        current_filter = self.hist_filters[self.hist_filter_idx]
        stats = self.db.get_stats_summary(filter_code=current_filter)
        trend = self.db.get_trend_data(filter_code=current_filter, max_points=min(30, w - 16))

        self.stdscr.attron(curses.color_pair(2) | curses.A_BOLD)
        self.stdscr.addstr(start_y, left_x, f"📊 Analytics & Lifetime Statistics [{t['filters'][current_filter]}]")
        self.stdscr.attroff(curses.color_pair(2) | curses.A_BOLD)

        total_calcs = stats.get("total_calcs") or 0
        avg_rate = stats.get("avg_rate") or 0.0
        min_rate = stats.get("min_rate") or 0.0
        max_rate = stats.get("max_rate") or 0.0
        sum_wins = stats.get("sum_wins") or 0
        sum_losses = stats.get("sum_losses") or 0
        sum_games = stats.get("sum_games") or 0

        self.stdscr.addstr(start_y + 2, left_x, f"• Total Calculations Recorded: {total_calcs:,}")
        self.stdscr.addstr(start_y + 3, left_x, f"• Average Win Rate:           {avg_rate:.2f}%")
        self.stdscr.addstr(start_y + 4, left_x, f"• Minimum / Maximum Win Rate:   {min_rate:.2f}% / {max_rate:.2f}%")
        self.stdscr.addstr(start_y + 5, left_x, f"• Cumulative Matches:          {sum_games:,} games (W: {sum_wins:,} | L: {sum_losses:,})")

        chart_y = start_y + 7
        self.stdscr.addstr(chart_y, left_x, "📈 Win Rate Trend Over Time:", curses.A_BOLD)
        
        if trend and len(trend) > 1:
            chart_height = 6
            rates = [r['raw_rate'] for r in trend]
            min_r = min(rates)
            max_r = max(rates)
            spread = max(1.0, max_r - min_r)
            
            for ch_row in range(chart_height):
                level_pct = max_r - (ch_row / (chart_height - 1)) * spread
                line_str = f"{level_pct:5.1f}% │"
                for r_val in rates:
                    norm = (r_val - min_r) / spread * (chart_height - 1)
                    if round(chart_height - 1 - norm) == ch_row:
                        line_str += "●"
                    elif chart_height - 1 - norm < ch_row:
                        line_str += "│"
                    else:
                        line_str += " "
                self.stdscr.addstr(chart_y + 1 + ch_row, left_x, line_str[:w - left_x - 2], curses.color_pair(1))
            
            axis_str = "       └" + "─" * len(rates)
            self.stdscr.addstr(chart_y + 1 + chart_height, left_x, axis_str[:w - left_x - 2], curses.A_DIM)
        else:
            self.stdscr.addstr(chart_y + 2, left_x + 2, "ℹ️ Need at least 2 records to render trend visualization.", curses.A_DIM)

    def _render_help_settings(self, h, w):
        t = self.t()
        left_x = 4
        start_y = 5
        
        self.stdscr.attron(curses.color_pair(2) | curses.A_BOLD)
        self.stdscr.addstr(start_y, left_x, "⚙️ Settings & Keybindings Guide")
        self.stdscr.attroff(curses.color_pair(2) | curses.A_BOLD)

        lines = [
            ("Language / ภาษา:", f"[ L ] Switch between Thai (TH) and English (EN)  (Current: {self.lang.upper()})"),
            ("Database Location:", f"{self.db.db_path}"),
            ("Storage Duration:", "Infinite SQLite Storage (Years of records supported)"),
            ("Data Export:", "[ E ] Export all records to CSV or JSON format"),
            ("Data Reset:", "[ X ] Clear history in current active filter"),
            ("", ""),
            ("Keyboard Shortcuts:", ""),
            ("1 - 6 / Tab:", "Switch Tabs (WR%, Find Win, Find Lose, History, Stats, Settings)"),
            ("Up / Down / Tab:", "Move between input fields / history rows"),
            ("Enter / C:", "Calculate & save current calculation to History"),
            ("Esc / Backspace:", "Clear active input field"),
            ("F:", "Cycle date filter (All Time, 1Y, 6M, 30D, 7D, Today)"),
            ("Q / Ctrl+C:", "Quit Application"),
        ]

        for idx, (label, val) in enumerate(lines):
            y = start_y + 2 + idx
            if y >= h - 3:
                break
            if label:
                self.stdscr.attron(curses.A_BOLD)
                self.stdscr.addstr(y, left_x, f"{label:<22}")
                self.stdscr.attroff(curses.A_BOLD)
            self.stdscr.addstr(y, left_x + 23, val[:w - left_x - 25])

    def _render_footer(self, h, w):
        t = self.t()
        status_line = h - 2
        if self.status_msg and (datetime.datetime.now().timestamp() - self.status_time < 5.0):
            self.stdscr.attron(curses.color_pair(3) | curses.A_BOLD)
            self.stdscr.addstr(status_line, 2, f"📢 {self.status_msg}"[:w - 4])
            self.stdscr.attroff(curses.color_pair(3) | curses.A_BOLD)
        else:
            actions = f"{t['buttons']['calculate']}  {t['buttons']['switchLang']}  {t['buttons']['export']}  {t['buttons']['quit']}"
            self.stdscr.addstr(status_line, max(0, (w - len(actions)) // 2), actions[:w - 2], curses.A_DIM)

        footer_y = h - 1
        footer_str = t["footer"]
        self.stdscr.attron(curses.A_DIM)
        self.stdscr.addstr(footer_y, max(0, (w - len(footer_str)) // 2), footer_str[:w - 2])
        self.stdscr.attroff(curses.A_DIM)

    def _handle_input(self):
        try:
            key = self.stdscr.getch()
        except KeyboardInterrupt:
            return False

        if key in (ord('q'), ord('Q')):
            return False

        if ord('1') <= key <= ord('6'):
            self.active_tab = key - ord('1')
            self.active_field = 0
            return True

        if key in (ord('l'), ord('L')):
            self.lang = "en" if self.lang == "th" else "th"
            self.db.set_setting("lang", self.lang)
            self.set_status(f"Language switched to {self.lang.upper()}")
            return True

        if key in (ord('f'), ord('F')):
            self.hist_filter_idx = (self.hist_filter_idx + 1) % len(self.hist_filters)
            self.hist_page = 0
            self.hist_selected_idx = 0
            self.set_status(f"Filter changed: {self.t()['filters'][self.hist_filters[self.hist_filter_idx]]}")
            return True

        if key in (ord('e'), ord('E')):
            export_path = os.path.expanduser(f"~/statscal_export_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")
            count = self.db.export_data(export_path, fmt="csv", filter_code=self.hist_filters[self.hist_filter_idx])
            self.set_status(f"{self.t()['messages']['exported']} {export_path} ({count} records)")
            return True

        if key in (ord('x'), ord('X')) and self.active_tab in (3, 4, 5):
            cleared = self.db.clear_history(self.hist_filters[self.hist_filter_idx])
            self.set_status(f"{self.t()['messages']['cleared_all']} ({cleared} deleted)")
            return True

        if self.active_tab == 3:
            if key in (curses.KEY_UP, ord('k')):
                if self.hist_selected_idx > 0:
                    self.hist_selected_idx -= 1
                return True
            elif key in (curses.KEY_DOWN, ord('j')):
                if self.hist_selected_idx < self.hist_page_size - 1:
                    self.hist_selected_idx += 1
                return True
            elif key in (ord('n'), ord('N'), curses.KEY_NPAGE):
                self.hist_page += 1
                self.hist_selected_idx = 0
                return True
            elif key in (ord('p'), ord('P'), curses.KEY_PPAGE):
                if self.hist_page > 0:
                    self.hist_page -= 1
                    self.hist_selected_idx = 0
                return True
            elif key in (ord('d'), ord('D'), curses.KEY_DC):
                current_filter = self.hist_filters[self.hist_filter_idx]
                records = self.db.get_records(filter_code=current_filter, limit=self.hist_page_size, offset=self.hist_page * self.hist_page_size)
                if records and self.hist_selected_idx < len(records):
                    rec = records[self.hist_selected_idx]
                    self.db.delete_record(rec['id'])
                    self.set_status(f"{self.t()['messages']['deleted']} (ID: {rec['id']})")
                return True

        if self.active_tab in (0, 1, 2):
            if key in (curses.KEY_DOWN, ord('\t'), 9):
                num_fields = 3
                self.active_field = (self.active_field + 1) % num_fields
                return True
            elif key in (curses.KEY_UP, curses.KEY_BTAB):
                num_fields = 3
                self.active_field = (self.active_field - 1) % num_fields
                return True
            elif key in (10, 13, curses.KEY_ENTER):
                self._save_active_calculation()
                return True
            elif key in (27,):
                self._clear_active_field()
                return True
            elif key in (curses.KEY_BACKSPACE, 127, 8):
                self._backspace_active_field()
                self._recompute_preview()
                return True
            elif 32 <= key <= 126:
                char = chr(key)
                self._type_active_field(char)
                self._recompute_preview()
                return True

        return True

    def _save_active_calculation(self):
        self._recompute_preview()
        if not self.calc_results:
            self.set_status(self.t()["messages"]["zero_games"])
            return

        res = self.calc_results
        modes = ["calculate_rate", "find_win", "find_lose"]
        mode = modes[self.active_tab]
        
        target = res['target_win'] if self.active_tab == 1 else (res['target_lose'] if self.active_tab == 2 else None)
        win_add = res['win_add'] if self.active_tab == 1 and res['win_add'] != "∞" else None
        lose_add = res['lose_add'] if self.active_tab == 2 and res['lose_add'] != "∞" else None

        rec_id = self.db.insert_record(
            mode=mode,
            wins=res['wins'],
            losses=res['losses'],
            raw_rate=res['raw_rate'],
            target_rate=target,
            win_to_add=win_add,
            lose_to_add=lose_add,
            note=self.note_str
        )
        self.set_status(f"{self.t()['messages']['saved']} (Record #{rec_id})")

    def _clear_active_field(self):
        if self.active_field == 0:
            self.wins_str = ""
        elif self.active_field == 1:
            self.losses_str = ""
        elif self.active_field == 2:
            if self.active_tab in (1, 2):
                self.custom_target_str = ""
            else:
                self.note_str = ""
        self._recompute_preview()

    def _backspace_active_field(self):
        if self.active_field == 0 and self.wins_str:
            self.wins_str = self.wins_str[:-1]
        elif self.active_field == 1 and self.losses_str:
            self.losses_str = self.losses_str[:-1]
        elif self.active_field == 2:
            if self.active_tab in (1, 2) and self.custom_target_str:
                self.custom_target_str = self.custom_target_str[:-1]
            elif self.note_str:
                self.note_str = self.note_str[:-1]

    def _type_active_field(self, char):
        if self.active_field in (0, 1):
            if char.isdigit():
                if self.active_field == 0:
                    self.wins_str += char
                else:
                    self.losses_str += char
        elif self.active_field == 2:
            if self.active_tab in (1, 2):
                if char.isdigit() or (char == '.' and '.' not in self.custom_target_str):
                    self.custom_target_str += char
            else:
                self.note_str += char

# ==============================================================================
# CLI / PIPELINE RUNNER
# ==============================================================================

def run_cli_mode(args):
    db = HistoryDB()
    wins = args.wins
    losses = args.losses
    target = args.target

    if args.export:
        fmt = "json" if args.export.lower() == "json" else "csv"
        path = args.output or f"statscal_export.{fmt}"
        count = db.export_data(path, fmt=fmt, filter_code="all")
        print(f"✓ Exported {count} records to {path}")
        return

    if args.history:
        limit = args.history if isinstance(args.history, int) else 10
        records = db.get_records(limit=limit)
        print(f"\n🕘 Last {len(records)} Calculations History:")
        print("─" * 70)
        print(f"{'ID':<4} {'Date':<17} {'Mode':<15} {'W/L':<10} {'WR%':<10} {'Result':<15}")
        print("─" * 70)
        for r in records:
            res_str = ""
            if r['mode'] == 'find_win':
                res_str = f"→ {r['target_rate']}% (+{r['win_to_add']})"
            elif r['mode'] == 'find_lose':
                res_str = f"→ {r['target_rate']}% (-{r['lose_to_add']})"
            print(f"{r['id']:<4} {str(r['timestamp'])[:16]:<17} {r['mode']:<15} {r['wins']}/{r['losses']:<8} {r['raw_rate']:<9.2f}% {res_str:<15}")
        print("─" * 70)
        return

    if wins is None or losses is None:
        print("Error: Total wins (-w) and total losses (-l) must be provided in CLI mode.")
        print("Usage: statscal 150 50   OR   statscal -w 150 -l 50")
        sys.exit(1)

    raw, total = calc_win_rate(wins, losses)
    _, target_win, win_add = calc_find_win(wins, losses, target)
    _, target_lose, lose_add = calc_find_lose(wins, losses, target)

    mode = "calculate_rate"
    if args.find_win:
        mode = "find_win"
    elif args.find_lose:
        mode = "find_lose"

    db.insert_record(
        mode=mode,
        wins=wins,
        losses=losses,
        raw_rate=raw,
        target_rate=target_win if mode == "find_win" else (target_lose if mode == "find_lose" else None),
        win_to_add=win_add if mode == "find_win" and win_add != "∞" else None,
        lose_to_add=lose_add if mode == "find_lose" and lose_add != "∞" else None,
        note=args.note or ""
    )

    if args.json_output:
        res = {
            "wins": wins,
            "losses": losses,
            "total_games": total,
            "raw_rate": round(raw, 4),
            "find_win": {
                "target_rate": target_win,
                "wins_needed": win_add
            },
            "find_lose": {
                "target_rate": target_lose,
                "losses_allowed": lose_add
            }
        }
        print(json.dumps(res, indent=2))
        return

    print("\n" + "=" * 55)
    print(f"  🏆 STATSCAL - WIN RATE SUMMARY")
    print("=" * 55)
    print(f"  • Total Matches:           {total:,} (Wins: {wins:,} | Losses: {losses:,})")
    print(f"  • Current Win Rate:        {raw:.2f}% ({raw:.4f}%)")
    print("─" * 55)
    print(f"  • Next Target (Win):       {target_win}%")
    print(f"  👉 Consecutive Wins Needed: {win_add}")
    print("─" * 55)
    print(f"  • Next Target (Loss):      {target_lose}%")
    print(f"  👉 Losses Allowed:         {lose_add}")
    print("=" * 55)
    print(f"  ✓ Saved to SQLite history (~/.local/share/statscal/history.db)\n")

def main():
    parser = argparse.ArgumentParser(description="Win Rate Statistics Calculator & Long-Term History TUI")
    parser.add_argument("pos_wins", nargs="?", type=int, help="Total Wins (positional)")
    parser.add_argument("pos_losses", nargs="?", type=int, help="Total Losses (positional)")
    parser.add_argument("-w", "--wins", type=int, help="Total Wins")
    parser.add_argument("-l", "--losses", type=int, help="Total Losses")
    parser.add_argument("-t", "--target", type=float, help="Target Win Rate percentage")
    parser.add_argument("--win", "--find-win", dest="find_win", action="store_true", help="Calculate wins needed to reach target WR%")
    parser.add_argument("--lose", "--find-lose", dest="find_lose", action="store_true", help="Calculate max losses before dropping WR%")
    parser.add_argument("--note", type=str, default="", help="Note or tag for history record")
    parser.add_argument("--history", nargs="?", const=10, type=int, help="Show recent history records")
    parser.add_argument("--export", type=str, choices=["csv", "json"], help="Export all history records")
    parser.add_argument("-o", "--output", type=str, help="Output file path for export")
    parser.add_argument("--json", dest="json_output", action="store_true", help="Output results in JSON format")
    parser.add_argument("--tui", action="store_true", help="Force interactive TUI mode")

    args = parser.parse_args()

    if args.pos_wins is not None and args.wins is None:
        args.wins = args.pos_wins
    if args.pos_losses is not None and args.losses is None:
        args.losses = args.pos_losses

    is_cli = (
        args.wins is not None or
        args.history is not None or
        args.export is not None or
        args.json_output
    ) and not args.tui

    if is_cli:
        run_cli_mode(args)
    else:
        try:
            curses.wrapper(lambda stdscr: StatscalTUI(stdscr).run())
        except Exception as e:
            print(f"Failed to start curses TUI: {e}")
            print("Launching interactive CLI fallback...")
            try:
                w_in = int(input("Enter Total Wins: "))
                l_in = int(input("Enter Total Losses: "))
                args.wins = w_in
                args.losses = l_in
                run_cli_mode(args)
            except Exception as ex:
                print(f"Exiting: {ex}")

if __name__ == "__main__":
    main()
