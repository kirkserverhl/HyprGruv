function y --description 'Yazi file manager with cwd restore'
    if not command -v yazi >/dev/null
        echo "yazi not installed"
        return 1
    end

    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file=$tmp
    set -l cwd (cat -- $tmp)
    if test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- $cwd
    end
    rm -f -- $tmp
end