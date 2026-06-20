# Matugen terminal colors + live reload (mirrors ~/.zshrc matugen section)

if not set -q KITTY_WINDOW_ID; and test -f "$HOME/.config/terminal-sequences"
    cat "$HOME/.config/terminal-sequences"
end

function _matugen_live_reload --on-event fish_prompt
    set -l stamp "$HOME/.cache/matugen/reload-stamp"
    set -l applied "$HOME/.cache/matugen/.reload-applied"
    if not test -f $stamp
        return
    end
    if test -f $applied; and not test $stamp -nt $applied
        return
    end

    if not set -q KITTY_WINDOW_ID; and test -f "$HOME/.config/terminal-sequences"
        cat "$HOME/.config/terminal-sequences"
    end
    touch -r $stamp $applied 2>/dev/null; or cp -f $stamp $applied 2>/dev/null
end