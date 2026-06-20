function ftext
    if test (count $argv) -lt 1
        echo "usage: ftext <pattern>" >&2
        return 1
    end
    grep -iIHrn --color=always $argv[1] . | less -r
end