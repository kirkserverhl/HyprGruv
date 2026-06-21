function alis --description 'List all custom abbreviations'
    if test -f ~/.config/fish/aliases.fish
        echo "=== Custom Fish Abbreviations ==="
        cat ~/.config/fish/aliases.fish | grep '^abbr ' | sed 's/abbr //' | sed "s/'//g"
    else
        echo "No aliases file found yet."
    end
end
