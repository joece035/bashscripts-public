 #!/bin/bash
# ============================================================
# fm-loader.sh — File Manager Integration
# ============================================================

# ============================================================

scripts_sync() {
    case "$1" in
        tm|wsl|gb)
            # Load file-manager if not already loaded
            command -v fm >/dev/null 2>&1 || source "$JOE_FUNCTIONS/11-bash-manager.sh"
            ;;
    esac
    case "$1" in
        tm)
           fm push "$htm/bashscripts/." "$hpc/bashscripts"
           cn lg b "DONE pushing bashscripts/ From ${JOE_ENV} → GIT-BASH (main SSOT)"
           ;;
        wsl)
           fm push "$hwsl/bashscripts/." "$htm/bashscripts"
           cn lg b "DONE pushing bashscripts/ From ${JOE_ENV} → TERMUX (from WSL)"
           ;;
        gb)
           wsl
           fm push "$hpc/bashscripts/." "$htm/bashscripts"
           cn lg b "DONE pushing bashscripts/ From ${JOE_ENV} → TERMUX (from GIT-BASH)"
           ;;
        *)
            cn 46 b "🚀 Usage: jsc [tm|wsl|gb]"
           echo -e "  tm  → push TERMUX    → GIT-BASH (SSOT)"
           echo -e "  wsl → push WSL       → TERMUX"
           echo -e "  gb  → push GIT-BASH  → TERMUX"
           ;;
    esac
}
alias jsc='scripts_sync'


# ----- Step 1: Set environment variables based on JOE_ENV -----#

tskg() {
    case "$JOE_ENV" in
        TERMUX|WSL)
            source "$HOME/task_generator/shell_integration.sh" 2>/dev/null
            ;;
        *)
            source "$hwsl/task_generator/shell_integration.sh" 2>/dev/null || \
            source "$HOME/task_generator/shell_integration.sh" 2>/dev/null
            ;;
    esac
}


dbsync() {
    if [[ -f "$DASHBOARD_DIR/sync-termux.sh" ]]; then
        source "$DASHBOARD_DIR/sync-termux.sh"
        if command -v synctm >/dev/null 2>&1; then
            synctm push
        else
            cn y b "synctm not found — run sync-termux.sh functions manually"
        fi
    else
        cn r b "sync-termux.sh not found in DASHBOARD_DIR"
    fi
    cn lg b "syncing dashboard with termux..."
}
alias dbpush='dbsync'


# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
#            SOURCE LEARNING SCRIPTS FILE            #
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ ##

 if [[ -d "$SSOT/joe.learn/block_engine/source_folder" ]]; then
   for learn_file in "$SSOT/joe.learn/block_engine/source_folder"/*; do
      [[ -f "$learn_file" ]] && 
      source "$learn_file"
   done
 fi   

 if [[ -f "$JOE_PLUGINS/block_engine/styles/block_style.sh" ]]; then
   source "$JOE_PLUGINS/block_engine/styles/block_style.sh"
 fi  


 if [[ -f "$JOE_PLUGINS/block_engine/entry.sh" ]]; then
   source $JOE_PLUGINS/block_engine/entry.sh
# Scripts with 'exit' or standalone output will kill the shell if sourced!
if [[ -d "$SSOT/tools" ]]; then
    for sh in "$SSOT/tools"/{ai_block,tools,merge,wtf}.sh; do
        [[ -f "$sh" ]] && source "$sh"
    done
fi




# ใช้งาน
#if [[ -d "$SSOT/lessons/example" ]]; then
 # for sh_ in "$SSOT/lessons/example"/*.sh; do
#   [[ -f "$sh_" ]] && source "$sh_"
#done
#fi
 
 nload() {
    source $JOE_ROOT/lessons/exercise/01-exercise_joe.sh
 }
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
#            alias source example_joe.sh             #
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
hermes_load() {
    [[ -f "$JOE_PLUGINS/hermes/hermes.sh" ]] && source "$JOE_PLUGINS/hermes/hermes.sh"
    [[ -f "$JOE_PLUGINS/hermes/hermes.sh" ]] || echo "hermes.sh not found in $JOE_PLUGINS/hermes"
}


   # NOTE: lessons/exercise/*.sh are test cases (test_case_w, exercise_dashboard, etc.)
   # — NOT production functions. They have side effects when sourced (call dashboard renderers)
   # and pollute the shell at startup. Source them manually only when running tests:
   #   source $SSOT/lessons/exercise/test_case_w.sh

  
