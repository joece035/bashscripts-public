 #!/bin/bash
# ============================================================
# fm-loader.sh — File Manager Integration
# ============================================================

# ============================================================

fm(){
    if [[ -z "$BASH_MANAGER" ]]; then
        [[ -f "$SSOT/tools/files_manage.sh" ]]&& source "$SSOT/tools/files_manage.sh" &&
            cn 10 b 'loading script is done ' || c y b "not found files_manage.sh"
    else
        c 45 b "BASH_MANAGER is Loaded"
    fi
    fm learn on &&
    fm "$@"
}




