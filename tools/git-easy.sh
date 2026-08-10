#!/bin/bash
# ============================================================
# git-easy.sh — user-friendly git for non-IT folks
# ============================================================
# One command: save your work and upload it to GitHub.
# No jargon, no flags, just questions.
#
# Usage:
#   giteasy           → save + upload flow
#   giteasy status    → just show what changed
# ============================================================

# ── Colors: use SSOT's cn() when running under the SSOT config,
#    fall back to plain ANSI when run standalone. No hardcoded paths. ──
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; DIM='\033[2m'; NC='\033[0m'
if declare -F cn >/dev/null 2>&1; then
    ok()   { cn 2 b "✓ $*"; }
    warn() { cn 3   "! $*"; }
    err()  { cn 1   "✗ $*"; }
    info() { cn 12  "› $*"; }
    dim()  { cn 8     "$*"; }
else
    ok()   { echo -e "${GREEN}✓${NC} $*"; }
    warn() { echo -e "${YELLOW}!${NC} $*"; }
    err()  { echo -e "${RED}✗${NC} $*"; }
    info() { echo -e "${BLUE}›${NC} $*"; }
    dim()  { echo -e "${DIM}$*${NC}"; }
fi

# ── Step 0: are we in a git repo? ──────────────────────────
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    err "This folder is not a git project yet."
    read -p "Do you want to turn it into one? (y/n): " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        git init >/dev/null 2>&1 && ok "Project created. Run 'giteasy' again to save your work."
    else
        echo "No problem. Run 'giteasy' again when you're ready."
    fi
    exit 0
fi

# ── Step 1: what's changed? ────────────────────────────────
branch="$(git branch --show-current 2>/dev/null || echo '(detached)')"
repo="$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")"

if [[ "$1" == "status" ]]; then
    echo
    info "Project: $repo  (branch: $branch)"
    if [[ -n "$(git status --porcelain)" ]]; then
        warn "You have unsaved changes:"
        git status --short | sed 's/^/   /'
    else
        ok "Everything is saved and up to date."
    fi
    exit 0
fi

echo
info "Project: $repo  (branch: $branch)"

# Categorize changes in plain words
new=$(git status --porcelain | grep -c '^??' || true)
mod=$(git status --porcelain | grep -cE '^.?[M]' || true)
del=$(git status --porcelain | grep -cE '^.?[D]' || true)

if [[ -z "$(git status --porcelain)" ]]; then
    ok "Nothing to save — your work is already saved and up to date."
    exit 0
fi

echo
if   [[ "$new" -gt 0 && "$mod" -eq 0 && "$del" -eq 0 ]]; then warn "You have $new new file(s):"
elif [[ "$mod" -gt 0 && "$new" -eq 0 && "$del" -eq 0 ]]; then warn "You changed $mod file(s):"
elif [[ "$del" -gt 0 && "$new" -eq 0 && "$mod" -eq 0 ]]; then warn "You removed $del file(s):"
else warn "You changed $mod, added $new new, and removed $del file(s):"; fi
git status --short | sed 's/^/   /'
echo

# ── Step 2: what did you do? ───────────────────────────────
default_msg="Update $repo"
read -p "What did you change? (one short sentence, Enter for '${default_msg}'): " msg
msg="${msg:-$default_msg}"
# keep it one line, safe for commit
msg="$(echo "$msg" | tr -d '\r\n' | sed 's/[[:space:]]\+/ /g')"

# ── Step 3: save ───────────────────────────────────────────
git add -A
if git commit -q -m "$msg"; then
    ok "Saved: \"$msg\""
else
    err "Could not save. Nothing was lost — ask a techie to look at this."
    exit 1
fi

# ── Step 4: upload to GitHub? ──────────────────────────────
has_upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)
read -p "Upload to GitHub now? (y/n, Enter = yes): " push_yn
push_yn="${push_yn:-y}"

if [[ ! "$push_yn" =~ ^[Yy]$ ]]; then
    echo
    ok "Saved locally. Run 'giteasy' again later to upload it."
    exit 0
fi

echo
info "Uploading to GitHub..."
if [[ -n "$has_upstream" ]]; then
    if git push -q; then ok "Uploaded to GitHub!"; else err "Upload failed — your work is safe locally. Try 'giteasy' again later."; exit 1; fi
else
    info "First upload for this project — setting it up..."
    if git push -q -u origin HEAD 2>&1; then ok "Uploaded to GitHub!"; else err "Upload failed — your work is safe locally. Try 'giteasy' again later."; exit 1; fi
fi

echo
ok "All done! $((new + mod + del)) file(s) saved and uploaded. 👍"


git_() {
    local repo=${SSOT}

    cd $repo && git status
    git add -A
    git commit -m "${1}"

}