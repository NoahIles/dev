# Interactive aliases, abbreviations, and helper functions
# (Editor / env vars live in environ.fish)

# Clipboard
alias pbcopy='wl-copy'
alias pbpaste='wl-paste'

# Utilities (guarded so the alias only exists when the command is installed)
command -q trash; and alias rm='trash'
command -q bat; and alias cat='bat'
command -q nvim; and alias vim='nvim'
command -q eza; and abbr --add tree 'eza --color=always --icons --tree'
alias code='/usr/bin/codium --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland'
alias mpvhdr='ENABLE_HDR_WSI=1 mpv --vo=dmabuf-wayland --vo=gpu-next --target-colorspace-hint --gpu-api=vulkan --gpu-context=waylandvk'
alias steamhdr='env ENABLE_GAMESCOPE_WSI=1 DXVK_HDR=1 DISABLE_HDR_WSI=1 steam' # -bigpicture
alias lg='lazygit --work-tree ~ --git-dir ~/.local/share/yadm/repo.git'

# Misc
alias pamcan='pacman'   # common typo
alias clear="printf '\033[2J\033[3J\033[1;1H'"
alias q='qs -c ii'

# Package management (see also cachyos-fish-config.fish)
abbr -a removepkg paru -Rns
abbr -a update paru -Syu --noconfirm
abbr -a listpkg checkupdates

# fd + fzf helpers — fn / fc live in /usr/local/bin/fn /usr/local/bin/fc
# modified from https://github.com/junegunn/fzf/blob/master/ADVANCED.md
abbr --add fdn --set-cursor=! "fd ! | fn"
abbr --add fdc --set-cursor=! "fd ! | fc"

# Taskwarrior
abbr -a t task
abbr -a tl task list
abbr -a ta task add
abbr -a --set-cursor=! td task ! done
abbr -a --set-cursor=! tn task next

# Interactive fzf pickers, inserted anywhere on the command line
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
