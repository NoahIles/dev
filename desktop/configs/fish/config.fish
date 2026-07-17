# Fish Top Level Config

# Environment variables (needed in non-interactive shells too)
source $HOME/.config/fish/user_scripts/environ.fish

function fish_prompt -d "Write out the prompt"
    # Shows up as USER@HOST /home/user/ >, with the directory colored.
    # $USER and $hostname are set by fish.
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

# peon-ping quick controls
function peon; bash /home/noah/.claude/hooks/peon-ping/peon.sh $argv; end

if status is-interactive
    set fish_greeting

    # Tool initialization
    command -q starship; and starship init fish | source
    zoxide init --cmd cd fish | source   # replaces cd with zoxide
    command -q mise; and mise activate fish | source
    command -q tv; and tv init fish | source

    # Load interactive scripts (aliases, keybindings, etc.).
    # environ.fish is already sourced above, so skip it here.
    for f in $HOME/.config/fish/user_scripts/*
        string match -q -- '*/environ.fish' $f; and continue
        source $f
    end
end
