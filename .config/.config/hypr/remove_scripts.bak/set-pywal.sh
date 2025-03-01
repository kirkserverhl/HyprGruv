shopt -s extglob

declare -r myname='set-pywal'
declare -r myver='1.1.1'

usage(){
    printf "%s v%s\n" "${myname}" "${myver}"
    echo
    printf "%s Pywal will use the wallpaper of variety"
    echo
    echo "  -h --help        display this help message and exit"
    echo "  -v --version     display version information and exit"
    echo
    echo "These options can be passed to the script:"
    echo "  -f    favorite"
    echo "  -p    previous"
    echo "  -n    next"
    echo " --u    update"
}

version(){
    printf "%s v%s\n" "${myname}" "${myver}"
    echo 'Copyright (c) 2024 Diggla Bass <kirkserverhl@gmail.com>'
}

#case "$1" in
#    -f) variety -f ;;
#    -p) variety -p ;;
#    -n) variety -n ;;
#esac
#}

if ! type "wal" >> /dev/null 2>&1; then
    echo -e \
        "\nThis script requires 'variety' tobe installed\n" \
        "\rPlease install it and return this script"
fi

if ! type "variety" >> /dev/null 2>&1; then
    echo -e \
        "\nThis script requires 'variety' tobe installed\n" \
        "\rPlease install it and return this script"
fi




if ! type "wal" >> /dev/null 2>&1 || type "variety" >> /dev/null 2>&1 ; then
    exit
fi



find-wallpaper(){
    current_wallpaper=$(cat $HOME/.config/variety/wallpaper/wallpaper.jpg.txt)
}


set-variety() {
    case "$1" in
        -f) variety -f ;;
        -p) variety -p ;;
        -n) variety -n ;;
    esac
}

set-wal() {
    wal -i $current_wallpaper
}



setwal() [
    case "$1" in
        -f) set-variety -f && find-wallpaper && sleep 1 && set-wal
        -p) set-variety -p && find-wallpaper && sleep 1 && set-wal
        -n) set-variety -n && find-wallpaper && sleep 1 && set-wal
    esac
]



while (( "$#" )); do
    case "$1" in
        -h|--help) usage; exit;;
        -v| --version) version; exit ;;
        *) setwal $1; exit ;;
    esac
done
