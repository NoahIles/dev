# Noah's Fish Config 

if status is-interactive
	# This is for Vi Bindings and settings
	#
	# add --no-erase if we don't want to reset all bindings
	fish_vi_key_bindings insert

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
  
  if command -q bat
    alias cat="bat"
  end

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

  if command -q zoxide
    zoxide init fish --cmd cd | source
  else
    echo "Zoxide Not installed"
  end

  if command -q starship
    starship init fish | source
  else
    echo "Starship not installed"
  end
end
