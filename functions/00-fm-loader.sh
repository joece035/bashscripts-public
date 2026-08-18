 #!/bin/bash
# ============================================================
# fm-loader.sh — File Manager Integration
# ============================================================

# ============================================================

fm(){
    if [[ -z "$BASH_MANAGER" ]]; then
        [[ -f "$SSOT/core/bash-manager.sh" ]]&& source "$SSOT/core/bash-manager.sh" &&
            cn 10 b 'loading script is done ' || c y b "not found bash-manager.sh"
    else
        c 45 b "BASH_MANAGER is Loaded"
    fi
    fm learn on &&
    fm "$@"
}

# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
#            SOURCE LEARNING SCRIPTS FILE            #
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ ##

 if [[ -d "$SSOT/joe.learn/block_engine/source_folder" ]]; then
   for learn_file in "$SSOT/joe.learn/block_engine/source_folder"/*; do
      [[ -f "$learn_file" ]] &&
      source "$learn_file"
   done
 fi

  if [[ -f "$SSOT/functions/joe-block/styles/block_style.sh" ]]; then
   source "$SSOT/functions/joe-block/styles/block_style.sh"
 fi


  if [[ -f "$SSOT/functions/joe-block/entry.sh" ]]; then
   source $SSOT/functions/joe-block/entry.sh
  fi


 #if [[ -f "$SSOT/lessons/custom_style.sh" ]]; then
  # source $SSOT/lessons/custom_style.sh
# fi
# Source ONLY library tools (NOT scripts like safe-edit.sh, color-chart.sh, ssot-audit.sh)
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
    : # formerly sourced lessons/exercise/01-exercise_joe.sh — removed 2026-08-18 (dead test code)
}
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
#            alias source example_joe.sh             #
# ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ #
hermes_load() {
    [[ -f "$SSOT/tools/hermes.sh" ]] && source "$SSOT/tools/hermes.sh"
    [[ -f "$SSOT/tools/hermes.sh" ]] || echo "hermes.sh not found in $SSOT/tools"
    source /home/usercivenz/bashscripts/tools/hermes.sh
}


   


