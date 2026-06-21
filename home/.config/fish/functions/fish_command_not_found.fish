function fish_command_not_found --on-event fish_command_not_found --description 'Zsh-style autocd: enter directories without typing cd'
    if test (count $argv) -eq 1
        and test -d $argv[1]
        cd $argv[1]
        return 0
    end

    __fish_default_command_not_found_handler $argv
end