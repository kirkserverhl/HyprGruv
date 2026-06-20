function extract
    for f in $argv
        if not test -f $f
            echo "Not a file: $f"
            continue
        end

        switch $f
            case '*.tar.bz2' '*.tbz2'
                tar xvjf $f
            case '*.tar.gz' '*.tgz'
                tar xvzf $f
            case '*.bz2'
                bunzip2 $f
            case '*.rar'
                if command -v unrar >/dev/null
                    unrar x $f
                else
                    echo "unrar not installed — cannot extract: $f"
                end
            case '*.gz'
                gunzip $f
            case '*.tar'
                tar xvf $f
            case '*.zip'
                unzip $f
            case '*.Z'
                uncompress $f
            case '*.7z'
                if command -v 7z >/dev/null
                    7z x $f
                else
                    echo "7z not installed — cannot extract: $f"
                end
            case '*'
                echo "Don't know how to extract: $f"
        end
    end
end