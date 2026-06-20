function cd --description 'Change directory and list contents'
    builtin cd $argv
    and ls
end