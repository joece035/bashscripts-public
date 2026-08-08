#!/usr/bin/env bash
# 12-git.sh — Git CLI helpers (SSOT)
# Source via joe.sh. Self-contained: safe to source multiple times.
# Author: Alpha for พี่โจ

# Avoid double-load
[[ -n "${_ALPHA_GIT_LOADED:-}" ]] && return 0
_ALPHA_GIT_LOADED=1

# ---- zsh: unalias names that collide with oh-my-zsh git plugin ----
# omz git plugin (loaded first in zshrc) defines ga/gaa/gcmsg/gco/gd/glog/gp/
# gclean as aliases. zsh expands aliases at parse time, so `gd() { ... }`
# becomes `git diff() { ... }` -> "parse error near `()'" / "defining
# function based on alias". Unalias before defining our functions.
# No-op in bash or when the alias doesn't exist.
unalias ga gaa gclean gcmsg gco gd glog gp 2>/dev/null || true

# ---- ANSI colors (no hardcode — matches 01-colors.sh style) ----
G_CYAN=$'\e[38;5;87m'
G_GRN=$'\e[38;5;82m'
G_YEL=$'\e[38;5;220m'
G_RED=$'\e[38;5;196m'
G_DIM=$'\e[38;5;245m'
G_RST=$'\e[0m'

_git_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

_git_need_repo() {
  local root
  root="$(_git_root)"
  if [[ -z "$root" ]]; then
    echo -e "${G_RED}✗ not a git repo${G_RST}" >&2
    return 1
  fi
  REPO_ROOT="$root"
  return 0
}

# ---- gs : git status (pretty) ----
gs() {
  if ! _git_need_repo; then return 1; fi
  echo -e "${G_CYAN}📂 $REPO_ROOT${G_RST}"
  git -C "$REPO_ROOT" status -sb
}

# ---- gd : git diff (short) ----
gd() {
  if ! _git_need_repo; then return 1; fi
  if [[ $# -gt 0 ]]; then
    git -C "$REPO_ROOT" diff "$@"
  else
    git -C "$REPO_ROOT" diff --stat
  fi
}

# ---- ga <files...> : git add ----
ga() {
  if ! _git_need_repo; then return 1; fi
  git -C "$REPO_ROOT" add "${@:-.}"
  echo -e "${G_GRN}✓ staged:${G_RST}"
  git -C "$REPO_ROOT" diff --cached --stat
}

# ---- gaa : git add --all ----
gaa() {
  if ! _git_need_repo; then return 1; fi
  git -C "$REPO_ROOT" add -A
  echo -e "${G_GRN}✓ all staged${G_RST}"
  git -C "$REPO_ROOT" diff --cached --stat
}

# ---- gcmsg "<msg>" : commit with message ----
gcmsg() {
  if ! _git_need_repo; then return 1; fi
  if [[ -z "${1:-}" ]]; then
    echo -e "${G_YEL}usage: gcmsg \"<message>\"${G_RST}" >&2
    return 1
  fi
  git -C "$REPO_ROOT" commit -m "$1"
}

# ---- gac "<msg>" : add all + commit ----
gac() {
  if ! _git_need_repo; then return 1; fi
  if [[ -z "${1:-}" ]]; then
    echo -e "${G_YEL}usage: gac \"<message>\"${G_RST}" >&2
    return 1
  fi
  git -C "$REPO_ROOT" add -A
  git -C "$REPO_ROOT" commit -m "$1"
}

# ---- gp : git push (current branch → origin) ----
gp() {
  if ! _git_need_repo; then return 1; fi
  local branch
  branch="$(git -C "$REPO_ROOT" symbolic-ref --short HEAD 2>/dev/null)"
  if [[ -z "$branch" ]]; then
    echo -e "${G_RED}✗ detached HEAD — no branch to push${G_RST}" >&2
    return 1
  fi

  # upstream check
  local upstream
  upstream="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"
  if [[ -z "$upstream" ]]; then
    echo -e "${G_YEL}⚠ no upstream — push with -u origin/${branch}${G_RST}"
    git -C "$REPO_ROOT" push -u origin "$branch" "$@"
  else
    git -C "$REPO_ROOT" push "$@" "$branch"
  fi
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    echo -e "${G_GRN}✓ pushed → origin/${branch}${G_RST}"
  else
    echo -e "${G_RED}✗ push failed (rc=$rc) — maybe need: gpl (pull --rebase first)${G_RST}" >&2
  fi
  return $rc
}

# ---- gpl : git pull (with rebase if local commits exist) ----
gpl() {
  if ! _git_need_repo; then return 1; fi
  local branch
  branch="$(git -C "$REPO_ROOT" symbolic-ref --short HEAD 2>/dev/null)"
  local upstream
  upstream="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"

  if [[ -z "$upstream" ]]; then
    echo -e "${G_YEL}⚠ no upstream — set with: gp (will -u automatically)${G_RST}" >&2
    return 1
  fi

  # If we have local commits, rebase to keep history clean
  local local_ahead
  local_ahead="$(git -C "$REPO_ROOT" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
  if [[ "${local_ahead:-0}" -gt 0 ]]; then
    echo -e "${G_DIM}↻ pulling with rebase (local commits: $local_ahead)${G_RST}"
    git -C "$REPO_ROOT" pull --rebase "$@"
  else
    git -C "$REPO_ROOT" pull "$@"
  fi
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    echo -e "${G_GRN}✓ pulled ← origin/${branch}${G_RST}"
  else
    echo -e "${G_RED}✗ pull failed (rc=$rc)${G_RST}" >&2
  fi
  return $rc
}

# ---- gsync : pull --rebase + push (one shot for "I want to be in sync") ----
gsync() {
  if ! _git_need_repo; then return 1; fi
  local branch
  branch="$(git -C "$REPO_ROOT" symbolic-ref --short HEAD 2>/dev/null)"
  echo -e "${G_CYAN}↻ syncing ${branch}...${G_RST}"

  if ! gpl; then return 1; fi
  if ! gp; then return 1; fi
  echo -e "${G_GRN}✓ in sync with origin/${branch}${G_RST}"
}

# ---- glog : compact log ----
glog() {
  if ! _git_need_repo; then return 1; fi
  local n="${1:-10}"
  git -C "$REPO_ROOT" log --oneline --graph --decorate -n "$n"
}

# ---- gnew <branch> : create + checkout ----
gnew() {
  if ! _git_need_repo; then return 1; fi
  if [[ -z "${1:-}" ]]; then
    echo -e "${G_YEL}usage: gnew <branch-name>${G_RST}" >&2
    return 1
  fi
  git -C "$REPO_ROOT" checkout -b "$1"
}

# ---- gco <branch> : checkout ----
gco() {
  if ! _git_need_repo; then return 1; fi
  if [[ -z "${1:-}" ]]; then
    git -C "$REPO_ROOT" branch -a
    return 0
  fi
  git -C "$REPO_ROOT" checkout "$1"
}

# ---- gundo : soft reset last commit (keep changes staged) ----
gundo() {
  if ! _git_need_repo; then return 1; fi
  echo -e "${G_YEL}↶ soft reset HEAD~1 (changes stay staged)${G_RST}"
  git -C "$REPO_ROOT" reset --soft HEAD~1
}

# ---- gstash [msg] : stash with optional message ----
gstash() {
  if ! _git_need_repo; then return 1; fi
  if [[ -n "${1:-}" ]]; then
    git -C "$REPO_ROOT" stash push -m "$1"
  else
    git -C "$REPO_ROOT" stash push
  fi
  echo -e "${G_GRN}✓ stashed${G_RST}"
}

# ---- gpop : pop last stash ----
gpop() {
  if ! _git_need_repo; then return 1; fi
  git -C "$REPO_ROOT" stash pop
}

# ---- gclean : ⚠ DESTRUCTIVE — show what would be removed first ----
gclean() {
  if ! _git_need_repo; then return 1; fi
  echo -e "${G_RED}⚠ DESTRUCTIVE${G_RST}"
  echo -e "${G_DIM}untracked + ignored files in repo root:${G_RST}"
  git -C "$REPO_ROOT" clean -ndx
  echo ""
  echo -e "${G_YEL}to actually delete, run: gclean!${G_RST}"
}

gclean!() {
  if ! _git_need_repo; then return 1; fi
  echo -e "${G_RED}⚠ removing untracked + ignored files${G_RST}"
  git -C "$REPO_ROOT" clean -fdx
}

# ---- help ----
ghelp() {
  cat <<'EOF'
git helpers (Alpha SSOT)
────────────────────────
  gs            git status -sb
  gd [args]     git diff (--stat default)
  ga [files]    git add (all if no args)
  gaa           git add -A
  gcmsg "msg"   git commit -m
  gac  "msg"    add all + commit
  gpl           git pull (rebase if local commits)
  gp            git push (auto -u on first push)
  gsync         gpl + gp (full sync)
  glog [n]      compact log (default 10)
  gnew <name>   checkout -b
  gco [name]    checkout (or list branches)
  gundo         soft reset HEAD~1
  gstash [msg]  stash with optional message
  gpop          pop last stash
  gclean        preview untracked+ignored files
  gclean!       actually delete them
  ghelp         this help

workflow (most common):
  gs → gac "fix: thing" → gsync
EOF
}
