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

fm(){
    local v=${1:-1}
    shift
    
    case "$v" in
            2)
                [[ -f "$SSOT/tools/files_manage.sh" ]]&& source "$SSOT/tools/files_manage.sh" &&
                cn 10 b 'loading script is done ' || c y b "not found files_manage.sh"
                fm "$@"
                ;;
            1)fm
                if command -v _check  > /dev/null 2>&1 ; then
                    if [[ -n "$BASH_MANAGER" ]] && [[ "$BASH_MANAGER" = "true" ]] ; then
                        c 45 b "BASH_MANAGER is Loaded"
                        fm "$@"
                    else
                        _check -f  "$SSOT/core/bash-manager.sh" "source" &&
                        fm learn on &&
                        fm "$@"
                    fi
                fi
               ;;
            *)
                echo 'usag fm 2 or fm 1 $@'
               ;;
    esac
}





