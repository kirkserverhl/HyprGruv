function trim
    set -l var (string join " " $argv)
    string trim $var
end