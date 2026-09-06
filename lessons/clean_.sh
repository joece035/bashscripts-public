del_cache(){
    sudo apt-get clean
    sudo apt-get autoremove -y
    rm -rf ~/.cache/*
    sudo rm -rf /tmp/*
    echo "Done!"
    echo "Free space: $(df -h / | awk 'NR==2 {print $4}')"
    df -h /
}
alias cc='del_cache'

clone() {

    local repo="${1:-pb}"
    local dep_dir="$HOME/bashscripts/"
    local rp_
    local bk_dir="${BACKUP_DIR}"/bashscripts_backup
    if [[ -d "${dep_dir}" ]]; then
        mkdir -p "${bk_dir}" &&
        mv "${dep_dir}" "${bk_dir}" &&
        cn 5 y "" " done backup ${dep_dir} "  && cd $HOME
    else    
        cn 5 y " ${dep_dir} not found in HOME " && cd $HOME
    fi
    case "$repo" in
        "pv"|"private")
            rp_="bashscripts.git"
            git "clone" "git@github.com:joece035/${rp_}" &&
            echo "Done cloning BASHSCRIPTS" ${rp_}  
        ;;
        "pb"|"public")
            rp_="bashscripts-public.git"
            git clone https://github.com/joece035/bashscripts-public.git ~/bashscripts
            bash ~/bashscripts/bootstrap/install.sh
        ;;
    esac

    pp
}


