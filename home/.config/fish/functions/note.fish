function note --description 'Quick capture a note to ~/notes/<category>/<title>.md'
    if test (count $argv) -lt 2
        echo "Usage:"
        echo "  na <category> <title>                  # open in editor to paste"
        echo "  na <category> <title> \"content\"      # one-liner with inline body"
        echo ""
        echo "Examples:"
        echo "  na hypr example"
        echo "  na hypr example \"pasted content #example #hypr\""
        echo ""
        echo "Find notes later: nf"
        return 1
    end

    set -l category $argv[1]
    set -l title $argv[2]
    set -l slug (string replace -a -r '[^a-zA-Z0-9._-]+' '-' -- $title)
    set slug (string trim -c '-' -- $slug)

    if test -z "$slug"
        set slug (date +%Y%m%d-%H%M%S)
    end

    set -l dir ~/notes/$category
    set -l filepath $dir/$slug.md
    mkdir -p $dir

    if test (count $argv) -ge 3
        set -l content (string join \n $argv[3..-1])
        printf '# %s\n\n%s\n' $title $content >$filepath
        echo "Note created: $filepath"
    else
        set -l editor nvim
        if set -q EDITOR; and test -n "$EDITOR"
            set editor $EDITOR
        end
        printf '# %s\n\n' $title >$filepath
        echo "Opening $filepath in $editor..."
        $editor $filepath
    end
end