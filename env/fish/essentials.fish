# Noah's Fish Config 


function __pick_file
  fd --type f | fzf
end
abbr -a !f --position anywhere --function __pick_file


function __pick_dir
  fd --type d | fzf
end
abbr -a !d --position anywhere --function __pick_dir


function __pick_grep
  set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case"
  true | fzf --ansi --disabled --query "$INITIAL_QUERY" \
      --bind "start:reload:$RG_PREFIX {q}" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      | tr ':' '\n' | head -n1
end
abbr -a !g --position anywhere --function __pick_grep


if status is-interactive
  # This is for Vi Bindings and settings
  #
  # add --no-erase if we don't want to reset all bindings
  fish_vi_key_bindings --no-erase insert

  # Fish Cursor settings
  set fish_cursor_default block
  set fish_cursor_insert line
  set fish_cursor_replace_one underscore
  set fish_cursor_replace underscore
  set fish_cursor_external line 
  set fish_cursor_visual block

  alias grep='grep --color=auto'
  alias jctl="journalctl -p 3 -xb"
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'

  #-----
  if command -q bat
    alias cat="bat"
  end
  #---- 

  if command -q eza
    ## Useful aliases
    # Replace ls with eza
    alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
    alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
    alias ll='eza -l --color=always --group-directories-first --icons'  # long format
    alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
    alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles
    abbr --add tree "eza --color=always --icons --tree"
  else
    echo "eza not installed"
  end

  #----
  if command -q zoxide
    zoxide init fish --cmd cd | source
  else
    echo "Zoxide Not installed"
  end
  #----
  if command -q starship
    starship init fish | source
  else
    echo "Starship not installed"
  end
  #---
  if command -q mise
    mise activate fish | source
  end
  #---

end

