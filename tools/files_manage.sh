


rename(){
    local f dest src f_final
    
    src="/mnt/f/Users/JoEz/Downloads/BIT"
    dest="/mnt/f/Users/JoEz/Downloads/new"
    shopt -s nullglob
    files=( "$src"/*(.mp4|.mov|.FLV|.avi|.webm)* )
    shopt -u nullglob
    mkdir -p "$dest"
    for f in "${files[@]}" ; do
        f_final="${dest}/$(basename "$f")"
        mv "${f}" "${f_final}"
        echo "✅ Done rename to ${f_final}"
    done
}

rename() {
    local src f tmp f_final i=1 dest
    local files=()

    src=/mnt/f/Users/JoEz/Downloads || return 1
    dest="/mnt/f/Users/JoEz/Downloads/new"
    shopt -s nullglob
    files=( "$src"/*FLV )
    shopt -u nullglob

    [[ ${#files[@]} -eq 0 ]] && {
        echo "❌ No mp4 files found."
        return 1
    }

    echo "📦 Found ${#files[@]} files"

    # 1. Move everything to temporary names
    for f in "${files[@]}"; do
        tmp="${f}.rename_tmp"
        mv -- "$f" "$tmp" || return 1
    done

    # 2. Rename sequentially
    for f in "$src"/*.rename_tmp; do
        f_final="${dest}/${i}.mp4"

        mv -- "$f" "$f_final" || return 1

        echo "✅ ${i}.mp4"

        ((i++))
    done
}