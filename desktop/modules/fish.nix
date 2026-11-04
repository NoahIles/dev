# fish — login shell. Opinionated module: the shell, its plugins, aliases and
# helper functions all live here (stable lane, rebuild to change). Longer
# functions and completions stay as plain .fish files under configs/fish and
# are linked per-file, so ~/.config/fish stays a real, writable dir for
# fish_variables. NixOS-only: the store links dangle when CachyOS boots.
{
  identity,
  pkgs,
  ...
}: {
  programs.fish.enable = true;
  users.users.${identity.username}.shell = pkgs.fish;

  home-manager.users.${identity.username} = {
    programs.fish = {
      enable = true;

      plugins = [
        # notification when a long command finishes in an unfocused terminal
        {
          name = "done";
          inherit (pkgs.fishPlugins.done) src;
        }
        # drops failed commands from history
        {
          name = "sponge";
          inherit (pkgs.fishPlugins.sponge) src;
        }
        # g* git abbreviations (gst, gco, gwip, …)
        {
          name = "plugin-git";
          inherit (pkgs.fishPlugins.plugin-git) src;
        }
        # 💡 tip when you type out something that has an alias/abbr
        {
          name = "abbreviation-tips";
          src = pkgs.fetchFromGitHub {
            owner = "gazorby";
            repo = "fish-abbreviation-tips";
            rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
            hash = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
          };
        }
      ];

      shellAliases = {
        pbcopy = "wl-copy";
        pbpaste = "wl-paste";
        cat = "bat";
        zed = "zeditor";
        lg = "lazygit --work-tree ~ --git-dir ~/.local/share/yadm/repo.git";
        clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
        mpvhdr = "ENABLE_HDR_WSI=1 mpv --vo=dmabuf-wayland --vo=gpu-next --target-colorspace-hint --gpu-api=vulkan --gpu-context=waylandvk";
        steamhdr = "env ENABLE_GAMESCOPE_WSI=1 DXVK_HDR=1 DISABLE_HDR_WSI=1 steam";
        peon = "bash $HOME/.claude/hooks/peon-ping/peon.sh";

        ls = "eza -al --color=always --group-directories-first --icons";
        la = "eza -a --color=always --group-directories-first --icons";
        ll = "eza -l --color=always --group-directories-first --icons";
        lt = "eza -aT --color=always --group-directories-first --icons";
        "l." = "eza -a | grep -e '^\\.'";

        tarnow = "tar -acf ";
        untar = "tar -zxvf ";
        wget = "wget -c ";
        psmem = "ps auxf | sort -nr -k 4";
        psmem10 = "ps auxf | sort -nr -k 4 | head -10";
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "......" = "cd ../../../../..";
        grep = "grep --color=auto";
        jctl = "journalctl -p 3 -xb";
      };

      shellAbbrs = {
        tree = "eza --color=always --icons --tree";
        update = "nh os switch --update --commit-lock-file";
        # fn / fc live in /usr/local/bin
        fdn = {
          setCursor = "!";
          expansion = "fd ! | fn";
        };
        fdc = {
          setCursor = "!";
          expansion = "fd ! | fc";
        };
        "!f" = {
          position = "anywhere";
          function = "__pick_file";
        };
        "!d" = {
          position = "anywhere";
          function = "__pick_dir";
        };
        "!g" = {
          position = "anywhere";
          function = "__pick_grep";
        };
      };

      functions = {
        fish_prompt = {
          description = "Fallback prompt when starship is missing";
          body = ''
            printf '%s@%s %s%s%s > ' $USER $hostname \
                (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
          '';
        };
        history = "builtin history --show-time='%F %T ' $argv";
        backup = {
          argumentNames = "filename";
          body = "cp $filename $filename.bak";
        };
        __pick_file = "fd --type f | fzf";
        __pick_dir = "fd --type d | fzf";
        __pick_grep = ''
          set RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case"
          true | fzf --ansi --disabled --query "$INITIAL_QUERY" \
              --bind "start:reload:$RG_PREFIX {q}" \
              --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
              --delimiter : \
              --preview 'bat --color=always {1} --highlight-line {2}' \
              --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
              | tr ':' '\n' | head -n1
        '';
        # !! and !$ (oh-my-fish/plugin-bang-bang)
        __history_previous_command = ''
          switch (commandline -t)
              case "!"
                  commandline -t $history[1]; commandline -f repaint
              case "*"
                  commandline -i !
          end
        '';
        __history_previous_command_arguments = ''
          switch (commandline -t)
              case "!"
                  commandline -t ""
                  commandline -f history-token-search-backward
              case "*"
                  commandline -i '$'
          end
        '';
      };

      shellInit = ''
        set -gx MANROFFOPT -c
        set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
        for p in ~/.local/bin ~/Applications/depot_tools ~/.spicetify
            test -d $p; and fish_add_path --global $p
        end
      '';

      interactiveShellInit = ''
        set fish_greeting

        starship init fish | source
        zoxide init --cmd cd fish | source

        # not declared in this repo; alias only when present
        command -q trash; and alias rm=trash
        command -q nvim; and alias vim=nvim
        command -q codium; and alias code='codium --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland'

        # vi mode; --no-erase keeps plugin bindings
        set -g fish_key_bindings fish_vi_key_bindings
        fish_vi_key_bindings --no-erase insert
        set fish_cursor_default block
        set fish_cursor_insert line
        set fish_cursor_replace_one underscore
        set fish_cursor_replace underscore
        set fish_cursor_external line
        set fish_cursor_visual block
        bind -M insert ! __history_previous_command
        bind -M insert '$' __history_previous_command_arguments

        set -g __done_min_cmd_duration 10000
        set -g __done_notification_urgency_level low

        # abbreviation-tips normally sets these on its fisher install event
        set -gx ABBR_TIPS_PROMPT "\n💡 \e[1m{{ .abbr }}\e[0m => {{ .cmd }}"
        set -gx ABBR_TIPS_REGEXES '(^(\w+\s+)+(-{1,2})\w+)(\s\S+)' '(^(\s?(\w-?)+){3}).*' '(^(\s?(\w-?)+){2}).*' '(^(\s?(\w-?)+){1}).*'
      '';

      # After all aliases/abbrs exist, rebuild abbreviation-tips' lookup table.
      # Replaces the plugin's __abbr_tips_init, which appends to universal
      # vars one entry at a time (a fish_variables write each, ~2.5s total).
      # Plain unexported globals: rebuilt every shell anyway, and an exported
      # copy from a parent shell would otherwise shadow them.
      shellInitLast = ''
        if status is-interactive
            set -l keys
            set -l values
            for a in (string replace -r '.*-- ' "" -- (abbr -s))
                set -l kv (string split -m1 -- ' ' $a)
                set -a keys $kv[1]
                set -a values (string trim -c "'" -- "$kv[2]")
            end
            for a in (string replace -r '.*-- ' "" -- (alias -s))
                set -l kv (string split -m2 -- ' ' $a)
                set -a keys "a__$kv[2]"
                set -a values (string trim -c "'" -- "$kv[3]")
            end
            set -eU __ABBR_TIPS_KEYS __ABBR_TIPS_VALUES 2>/dev/null
            set -gu __ABBR_TIPS_KEYS $keys
            set -gu __ABBR_TIPS_VALUES $values
        end
      '';
    };

    xdg.configFile = {
      "fish/functions" = {
        source = ../configs/fish/functions;
        recursive = true;
      };
      "fish/completions" = {
        source = ../configs/fish/completions;
        recursive = true;
      };
      "fish/conf.d/fish_frozen_theme.fish".source = ../configs/fish/conf.d/fish_frozen_theme.fish;
    };
  };
}
