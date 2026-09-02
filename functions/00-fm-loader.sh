 #!/bin/bash
# ============================================================
# fm-loader.sh — File Manager Integration
# ============================================================

# ============================================================

fm_(){

    if command -v fm >/dev/null 2>&1 ; then   
        cn 45 b "BASH_MANAGER is Loaded" &&
        fm learn on &&
        fm "$@"
    else
        _check -f  "$SSOT/core/bash-manager.sh" "source" &&
        fm learn on &&
        fm "$@"
    fi

}

fn(){
				if
        _check -f "$SSOT/tools/files_manage.sh" "source" && 
        cn 10 b 'loading script is done ' && 
        fn "$@"
    else
        cn 198 b "not found _check"
        return 1
    fi
}








