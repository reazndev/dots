source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end


# Added by Antigravity CLI installer
set -gx PATH "/home/reazn/.local/bin" $PATH

# Initialize zoxide to replace cd
zoxide init fish --cmd cd | source

# Initialize Starship prompt
starship init fish | source

# Case-insensitive cd and command fallback for local directories
function cd --wraps=__zoxide_z
    if test (count $argv) -eq 1
        set -l target $argv[1]
        if not test -d "$target"; and not string match -q '*/*' "$target"
            set -l match (find . -maxdepth 1 -iname "$target" -type d)
            if test -n "$match"
                set target (string replace -r '^\./' '' $match[1])
            end
        end
        __zoxide_z "$target"
    else
        __zoxide_z $argv
    end
end

function fish_command_not_found
    set -l cmd $argv[1]
    if not string match -q '*/*' "$cmd"
        set -l match (find . -maxdepth 1 -iname "$cmd" -type d)
        if test -n "$match"
            set -l dir (string replace -r '^\./' '' $match[1])
            cd "$dir"
            return 0
        end
    end

    if functions -q __fish_default_command_not_found_handler
        __fish_default_command_not_found_handler $argv
    else
        echo "Command not found: $cmd"
        return 127
    end
end

# Git Aliases & Functions
alias g="git status"
alias gsw="git switch"
alias gswb="git switch -c"
alias gbl="git branch -a"

function gac
    git add -A && git commit -m "$argv"
end

function gp
    set -l branch (git branch --show-current)
    if test -n "$branch"
        git push -u origin $branch
    else
        git push
    end
end

# Customize fish colors for readability
set -g fish_color_autosuggestion 999999

# kimi-code
fish_add_path -g "/home/reazn/.kimi-code/bin"
