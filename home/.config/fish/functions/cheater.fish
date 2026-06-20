function cheater
    set -l cheat "$HOME/.config/tmux/cheatsheet.txt"
    if not test -f $cheat
        echo "No cheat sheet: $cheat" >&2
        return 1
    end
    if command -v bat >/dev/null
        env PAGER=cat bat --paging=never --decorations=never $cheat
    else
        cat $cheat
    end
end