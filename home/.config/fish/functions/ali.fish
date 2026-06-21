function ali --description 'Create a new Fish abbreviation with optional comment'
    if test (count $argv) -lt 2
        echo "Usage: ali <name> <command...> [# comment]"
        echo "Example: ali ga git add . # Add all files recursively"
        echo "         ali ll ls -la # Long list with hidden files"
        return 1
    end

    set abbr_name $argv[1]
    set rest $argv[2..-1]

    # Check if there's a comment at the end (starts with #)
    set comment ""
    if string match -q "#*" $rest[-1]
        set comment (string join " " $rest[-1..-1])
        set command_args $rest[1..-2]
    else
        set command_args $rest
    end

    set escaped_cmd (string join " " $command_args)

    # Build the line with comment if present
    if test -n "$comment"
        echo "abbr $abbr_name '$escaped_cmd'  # $comment" >> ~/.config/fish/aliases.fish
    else
        echo "abbr $abbr_name '$escaped_cmd'" >> ~/.config/fish/aliases.fish
    end

    # Deduplicate (keep newest version)
    awk '!seen[$0]++' ~/.config/fish/aliases.fish > ~/.config/fish/aliases.fish.tmp
    mv ~/.config/fish/aliases.fish.tmp ~/.config/fish/aliases.fish

    # Apply immediately
    source ~/.config/fish/aliases.fish

    if test -n "$comment"
        echo "✓ Abbreviation created: $abbr_name → $escaped_cmd"
        echo "  Comment: $comment"
    else
        echo "✓ Abbreviation created: $abbr_name → $escaped_cmd"
    end
end
