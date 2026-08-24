#!/bin/bash
shell_setup(){
    
    local pf=""

        case "$JOE_ENV" in
                TERMUX)
                    if [[ ! -f "$HOME/.bashrc" ]]; then
                         pf="${SSOT}/profiles/termux/.bashrc"
                        if [[ -f "$pf" ]]; then
                            ln -sf "$pf" "$HOME/.bashrc" && echo "symlink $pf >>> $HOME/.bashrc done" || echo "FAIL"
                        else
                            echo "not found $pf"    
                        fi
                    fi     
                    if [[ ! -f "$HOME/.zshrc" ]]; then
                         pf="${SSOT}/profiles/termux/.zshrc"
                         if [[ -f "$pf" ]]; then
                             ln -sf "$pf" "$HOME/.zshrc" && echo "symlink $pf >>> $HOME/.zshrc done" || echo "FAIL"
                         else
                             echo "not found $pf"
                         fi
                    fi
                    ;;
                MUMU) 
                    if [[ ! -f "$HOME/.bashrc" ]]; then
                         pf="${SSOT}/profiles/mumu/.bashrc"
                         if [[ -f "$pf" ]]; then
                            ln -sf "$pf" "$HOME/.bashrc" && echo "symlink $pf >>> $HOME/.bashrc done" || echo "FAIL"
                         else
                            echo "not found $pf"
                         fi
                    fi
                    if [[ ! -f "$HOME/.zshrc" ]]; then
                         pf="${SSOT}/profiles/mumu/.zshrc"
                         if [[ -f "$pf" ]]; then
                             ln -sf "$pf" "$HOME/.zshrc" && echo "symlink $pf >>> $HOME/.zshrc done" || echo "FAIL"
                         else
                             echo "not found $pf"
                         fi
                    fi
                    ;;
                WSL)
                    if [[ ! -f "$HOME/.bashrc" ]]; then
                         pf="${SSOT}/profiles/wsl/.bashrc"
                         if [[ -f "$pf" ]]; then
                            ln -sf "$pf" "$HOME/.bashrc" && echo "symlink $pf >>> $HOME/.bashrc done" || echo "FAIL"
                         else
                            echo "not found $pf"
                         fi
                    fi
                    ;;
                GIT-BASH )
                    if [[ ! -f "$HOME/.bashrc" ]]; then
                         pf="${SSOT}/profiles/git-bash/.bashrc"
                         if [[ -f "$pf" ]]; then
                            ln -sf "$pf" "$HOME/.bashrc" && echo "symlink $pf >>> $HOME/.bashrc done" || echo "FAIL"
                         else
                            echo "not found $pf"
                         fi
                    fi
                    ;;
                *) echo unknow ;;    
         esac               
}
shell_setup

shell_setup_() {
    local env_dir=""
    local files=(".bashrc")

    case "$JOE_ENV" in
        TERMUX)   env_dir="termux";   files+=(".zshrc") ;;
        MUMU)     env_dir="mumu";     files+=(".zshrc") ;;
        WSL)      env_dir="wsl" ;;
        GIT-BASH) env_dir="git-bash" ;;
        *)        echo "Unknown or unsupported JOE_ENV: '$JOE_ENV'"; return 1 ;;
    esac

    for file in "${files[@]}"; do
        local target="$HOME/$file"
        local source="${SSOT}/profiles/${env_dir}/$file"

        if [[ ! -f "$source" ]]; then
            echo "Source not found: $source"
            continue
        fi

        # ถ้ายังไม่มีไฟล์ หรือเป็น symlink เก่า ให้สร้าง/แทนที่ด้วย ln -sff
        if [[ ! -e "$target" && ! -L "$target" ]]; then
            ln -sff "$source" "$target" && echo "symlink $source >>> $target [DONE]" || echo "FAIL: $target"
        fi
    done
}
