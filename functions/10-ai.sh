#!/bin/bash
# ============================================================
# 10-ai.sh — AI-Powered Smart Terminal for Joe
# ============================================================
# Integration with Hermes Agent for natural language commands
# and intelligent suggestions.
#
# Stage: 10 (after all core functions loaded)
# Dependencies: 08-nexus.sh, 01-colors.sh
# ============================================================

# ============================================================
# 1. AI CONFIGURATION (SSOT)
# ============================================================
export AI_HERMES_BIN="${AI_HERMES_BIN:-hermes}"
export AI_SESSION_DIR="${HOME}/.hermes/sessions"
export AI_STATE_DB="${HOME}/.hermes/state.db"
export AI_SUGGESTIONS_FILE="${HOME}/.hermes/suggestions.json"

# ============================================================
# 2. AI STATUS CHECK
# ============================================================
ai_status() {
    local status="offline"
    local session_count=0
    local last_active="never"
    
    # Check if Hermes is installed
    if command -v "$AI_HERMES_BIN" &>/dev/null; then
        # Check if there are active sessions
        if [[ -d "$AI_SESSION_DIR" ]]; then
            session_count=$(find "$AI_SESSION_DIR" -name "*.jsonl" -type f | wc -l)
        fi
        
        # Check if state.db exists (indicates Hermes has been used)
        if [[ -f "$AI_STATE_DB" ]]; then
            last_active=$(stat -c %y "$AI_STATE_DB" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
        fi
        
        status="online"
    fi
    
    echo "${status}|${session_count}|${last_active}"
}

# ============================================================
# 3. AI NATURAL LANGUAGE COMMAND
# ============================================================
joe_ai() {
    local input="$*"
    
    if [[ -z "$input" ]]; then
        cn r b "❌ Usage: joe ai <natural language command>"
        cn y b "Example: joe ai 'show me docker containers'"
        cn y b "Example: joe ai 'create backup of my project'"
        return 1
    fi
    
    cn 51 b "🤖 AI Processing: $input"
    echo ""
    
    # Environment-aware: use SSOT variables from 3worlds.sh
    case "${JOE_ENV:-}" in
        WSL|TERMUX|MUMU)
            # ใช้ hermes ตรงๆ บนเครื่องที่มี
            if ! command -v "$AI_HERMES_BIN" &>/dev/null; then
                cn r b "❌ Hermes Agent not found. Install with: pip install hermes-agent"
                return 1
            fi
            "$AI_HERMES_BIN" chat "$input" 2>&1
            ;;
        GIT-BASH)
            # ใช้ SSH tunnel ไป WSL ผ่าน SSOT variables (ไม่ hardcode)
            # ตัวแปรทั้งหมดมาจาก 00-env.sh แล้ว: $WSL_IP, $WSL_USER, $WSL_PORT
            if [[ -z "${WSL_IP:-}" ]]; then
                cn r b "❌ WSL_IP not set. Check 00-env.sh"
                return 1
            fi
            
            local ssh_port="${WSL_PORT:-22}"
            local ssh_user="${WSL_USER:-usercivenz}"
            local ssh_host="${WSL_IP}"
            
            # ใช้ wsl() function จาก 3worlds.sh ถ้ามี
            if declare -f wsl &>/dev/null; then
                cn y b "📡 tunneling to WSL hermes via wsl()..."
                wsl "hermes chat '$input'" 2>&1
            else
                # fallback: SSH ตรงๆ ด้วย SSOT variables
                cn y b "📡 tunneling to WSL hermes via SSH..."
                ssh -p "$ssh_port" "${ssh_user}@${ssh_host}" "hermes chat '$input'" 2>&1
            fi
            ;;
        *)
            cn r b "❌ Unknown environment: ${JOE_ENV:-none}"
            cn y b "💡 Available on: WSL, Termux, Linux"
            return 1
            ;;
    esac
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        cn lg b "✅ AI command completed"
    else
        cn r b "⚠️  AI command finished with errors (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Alias for convenience
alias ai='joe_ai'
alias ask='joe_ai'

# ============================================================
# 4. AI CONTEXT ANALYZER
# ============================================================
ai_context_analyze() {
    local context=""
    
    # Current directory
    context+="dir:$(pwd)|"
    
    # Git status (if in git repo)
    if git rev-parse --git-dir &>/dev/null 2>&1; then
        local git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        local git_status=$(git status --porcelain 2>/dev/null | wc -l)
        context+="git_branch:${git_branch}|git_modified:${git_status}|"
    fi
    
    # Docker status (if docker available)
    if command -v docker &>/dev/null 2>&1; then
        local docker_containers=$(docker ps -q 2>/dev/null | wc -l)
        context+="docker_running:${docker_containers}|"
    fi
    
    # Recent files (last 5 modified)
    local recent_files=$(find . -maxdepth 1 -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -5 | awk '{print $2}' | tr '\n' ',')
    context+="recent_files:${recent_files}|"
    
    # Session info
    context+="user:$(whoami)|hostname:$(hostname)|date:$(date +%Y-%m-%d)|"
    
    echo "$context"
}

# ============================================================
# 5. AI SMART SUGGESTIONS
# ============================================================
ai_suggest() {
    local context=$(ai_context_analyze)
    local suggestions=()
    
    # Rule-based suggestions (fast, no API call)
    
    # Git suggestions
    if [[ "$context" == *"git_modified:"* ]]; then
        local modified_count=$(echo "$context" | grep -o "git_modified:[0-9]*" | cut -d: -f2)
        if [[ "$modified_count" -gt 0 ]]; then
            suggestions+=("📝 You have $modified_count modified files. Run: git status")
        fi
    fi
    
    # Docker suggestions
    if [[ "$context" == *"docker_running:0"* ]]; then
        suggestions+=("🐳 No Docker containers running. Start with: docker start <container>")
    fi
    
    # Directory-based suggestions
    local current_dir=$(basename "$(pwd)")
    case "$current_dir" in
        dashboard|Dashboard)
            suggestions+=("📊 Dashboard project detected. Run: python app.py")
            ;;
        bashscripts|bash*)
            suggestions+=("🔧 Bashscripts detected. Run: joe help")
            ;;
        hermes_vault|nexus_vault)
            suggestions+=("📚 Vault detected. Run: vault status")
            ;;
    esac
    
    # Time-based suggestions
    local hour=$(date +%H)
    if [[ "$hour" -lt 10 ]]; then
        suggestions+=("🌅 Good morning! Start with: joe status")
    elif [[ "$hour" -lt 18 ]]; then
        suggestions+=("☀️  Afternoon focus time. Run: joe monitor")
    else
        suggestions+=("🌙 Evening. Run: joe backup")
    fi
    
    # Display suggestions
    if [[ ${#suggestions[@]} -eq 0 ]]; then
        cn gr b "💡 No specific suggestions. Try: joe ai <your question>"
    else
        cn 51 b "💡 Smart Suggestions:"
        for sug in "${suggestions[@]}"; do
            cn w b "   • $sug"
        done
    fi
}

# ============================================================
# 6. AI QUICK COMMANDS (Pre-built actions)
# ============================================================
ai_quick() {
    local action="$1"
    shift
    
    case "$action" in
        status|st)
            ai_suggest
            ;;
        analyze|an)
            ai_context_analyze
            ;;
        backup|bk)
            joe_ai "backup current directory"
            ;;
        sync|sy)
            joe_ai "sync files across worlds"
            ;;
        clean|cl)
            joe_ai "clean temporary files"
            ;;
        deploy|dp)
            joe_ai "deploy current project"
            ;;
        *)
            cn r b "Unknown action: $action"
            cn y b "Available: status, analyze, backup, sync, clean, deploy"
            return 1
            ;;
    esac
}

# Alias
alias aiq='ai_quick'

# ============================================================
# 7. AI BLOCK DISPLAY (for JOE_BLOCK integration)
# ============================================================
ai_block_data() {
    local status_data=$(ai_status)
    local status=$(echo "$status_data" | cut -d'|' -f1)
    local sessions=$(echo "$status_data" | cut -d'|' -f2)
    local last_active=$(echo "$status_data" | cut -d'|' -f3)
    
    local status_icon
    local status_color
    case "$status" in
        online)  status_icon="🟢"; status_color="lg b" ;;
        offline) status_icon="🔴"; status_color="r b" ;;
        *)       status_icon="⚪"; status_color="gr b" ;;
    esac
    
    # Output format for JOE_BLOCK: EMOJI_L|LABEL|value|EMOJI_R
    echo "🤖|AI Status|${status}|${status_icon}"
    echo "🧠|Sessions|${sessions}|📊"
    echo "⏰|Last Active|${last_active}|📅"
}

# ============================================================
# 8. AI HELP SYSTEM
# ============================================================
ai_help() {
    cat << 'EOF'

🤖 AI-POWERED SMART TERMINAL — Help

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BASIC USAGE:
  joe ai <question>        → Ask AI anything
  ai <question>            → Alias for joe ai
  ask <question>           → Alias for joe ai

QUICK COMMANDS:
  aiq status               → Get smart suggestions
  aiq analyze              → Analyze current context
  aiq backup               → AI-assisted backup
  aiq sync                 → AI-assisted sync
  aiq clean                → AI-assisted cleanup
  aiq deploy               → AI-assisted deploy

CONTEXT AWARENESS:
  ai_context_analyze       → Show detected context
  ai_suggest               → Get smart suggestions

INTEGRATION:
  joe status               → Shows AI status in dashboard
  joe ai <command>         → Natural language commands

EXAMPLES:
  joe ai "what's in this directory?"
  ai "create a backup of my project"
  ask "how do I start docker containers?"
  aiq status
  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

# ============================================================
# 9. JOE MAIN COMMAND DISPATCHER (with AI integration)
# ============================================================
joe() {
    local cmd="${1:-help}"
    shift 2>/dev/null
    
    case "$cmd" in
        ai|ask)
            joe_ai "$@"
            ;;
        ai-status|ais)
            ai_status
            ;;
        ai-context|aic)
            ai_context_analyze
            ;;
        ai-suggest|aisg)
            ai_suggest
            ;;
        ai-quick|aiq)
            ai_quick "$@"
            ;;
        ai-help|aih)
            ai_help
            ;;
        ai-block|aib)
            ai_block_render "$@"
            ;;
        status|st)
            _joe_status "$@"
            ;;
        monitor|mon)
            _joe_monitor "$@"
            ;;
        help|h|--help|-h)
            _joe_help "$@"
            ;;
        *)
            # Try to run as ai command if not found
            if command -v "joe_$cmd" &>/dev/null; then
                "joe_$cmd" "$@"
            else
                cn r b "Unknown command: $cmd"
                cn y b "Run: joe help"
                return 1
            fi
            ;;
    esac
}

# ============================================================
# 10. JOE STATUS DISPLAY
# ============================================================
_joe_status() {
    local show_ai="${1:-full}"
    
    cn 51 b "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cn lg b "  🚀 JOE'S PERSONAL COMMAND CENTER — Status"
    cn 51 b "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Environment info
    cn w b "  🌍 Environment: ${JOE_ENV:-unknown}"
    cn w b "  📂 Script Path: ${SSOT:-unknown}"
    cn w b "  🏠 Home: ${HOME}"
    echo ""
    
    # AI Status (if full)
    if [[ "$show_ai" == "full" ]]; then
        cn 51 b "  🤖 AI Integration:"
        local ai_state=$(ai_status 2>/dev/null || echo "offline||unknown")
        local status=$(echo "$ai_state" | cut -d'|' -f1)
        local sessions=$(echo "$ai_state" | cut -d'|' -f2)
        
        case "$status" in
            online)  cn lg b "     Status: 🟢 Online" ;;
            *)       cn r b "     Status: 🔴 Offline" ;;
        esac
        cn w b "     Sessions: $sessions"
        echo ""
    fi
    
    cn 51 b "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# 11. JOE MONITOR (Real-time dashboard)
# ============================================================
_joe_monitor() {
    clear
    cn 51 b "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cn lg b "  📊 JOE MONITOR — Real-time Dashboard"
    cn 51 b "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # AI Block
    ai_block_render
    
    echo ""
    cn gr b "  Press Ctrl+C to exit"
    cn 51 b "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# 12. JOE HELP SYSTEM
# ============================================================
_joe_help() {
    cat << 'EOF'

🚀 JOE'S PERSONAL COMMAND CENTER — Help

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 AI COMMANDS:
  joe ai <question>        → Ask AI anything (natural language)
  joe ai-status            → Show AI connection status
  joe ai-context           → Analyze current context
  joe ai-suggest           → Get smart suggestions
  joe ai-quick <action>    → Quick AI actions (backup/sync/clean/deploy)
  joe ai-help              → Show AI help
  joe ai-block             → Show AI status block

📊 STATUS & MONITORING:
  joe status               → Show system status
  joe monitor              → Real-time dashboard

🔧 ALIASES:
  ai <question>            → Alias for joe ai
  ask <question>           → Alias for joe ai
  aiq <action>             → Alias for joe ai-quick

📝 EXAMPLES:
  joe ai "what's in this directory?"
  joe ai "create a backup"
  ai "how do I start docker?"
  aiq status
  joe status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

# ============================================================
# 13. ALIASES
# ============================================================
alias ai-status='ai_status'
alias ai-context='ai_context_analyze'
alias ai-suggest='ai_suggest'
alias ai-help='ai_help'
