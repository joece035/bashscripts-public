 #!/bin/bash
# ============================================================
# fm-loader.sh — File Manager Integration
# ============================================================

# ============================================================

fm(){

    if command -v _check  > /dev/null 2>&1 ; then
        if [[ -n "$BASH_MANAGER" ]] && [[ "$BASH_MANAGER" = "true" ]] ; then
            c 45 b "BASH_MANAGER is Loaded" &&
            fm "$@"
        else
            _check -f  "$SSOT/core/bash-manager.sh" "source" &&
            fm learn on &&
            fm "$@"
        fi
    else
        cn 198 b "not found _check"
        return 1
    fi

}

fn(){
    if command -v _check  > /dev/null 2>&1 ; then
        _check "$SSOT/tools/files_manage.sh" "source" && 
        cn 10 b 'loading script is done ' && fn "$@"
    else
        cn 198 b "not found _check"
        return 1
    fi
}






