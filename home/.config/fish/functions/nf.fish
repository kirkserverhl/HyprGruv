function nf --description 'Fuzzy-find and open a note from ~/notes'
    set -l notes_dir ~/notes

    if not test -d $notes_dir
        echo "No ~/notes directory yet."
        return 1
    end

    if not command -v fzf >/dev/null
        echo "fzf is required for nf"
        return 1
    end

    set -l candidates
    if test (count $argv) -gt 0
        set -l query (string join ' ' $argv)
        set candidates (rg -l --smart-case $query $notes_dir -g '*.md' 2>/dev/null)
        if test -z "$candidates"
            echo "No notes matching: $query"
            return 1
        end
    else
        set candidates (find $notes_dir -name '*.md' -not -path '*/.git/*' 2>/dev/null | sort)
    end

    set -l selected (
        printf '%s\n' $candidates |
        fzf --prompt 'notes> ' \
            --header 'enter: open  esc: cancel' \
            --preview 'bat -n --color=always --style=numbers,changes --line-range :80 {}' \
            --preview-window 'right:60%:wrap'
    )

    if test -z "$selected"
        return 0
    end

    set -l editor nvim
    if set -q EDITOR; and test -n "$EDITOR"
        set editor $EDITOR
    end
    $editor $selected
end