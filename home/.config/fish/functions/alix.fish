function alix --description 'Delete a Fish abbreviation'
    if test (count $argv) -eq 0
        echo "Usage: alix <name>"
        echo "Example: alix ga"
        return 1
    end

    set name $argv[1]

    if test -f ~/.config/fish/aliases.fish
        grep -v "^abbr $name " ~/.config/fish/aliases.fish > ~/.config/fish/aliases.fish.tmp
        mv ~/.config/fish/aliases.fish.tmp ~/.config/fish/aliases.fish

        source ~/.config/fish/aliases.fish
        echo "✓ Abbreviation '$name' removed"
    else
        echo "No aliases file."
    end
end
