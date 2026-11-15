# The two ways Claude Code starts:
#
#   claude       the whole process (file tools, Bash, hooks, MCP servers) runs
#                inside Anthropic's sandbox runtime. Default.
#   claude-host  no box. For work on this machine itself: rebuilds, sudo, the
#                compositor. `claude-host --resume <id>` carries a boxed session
#                across.
#
# Both get PATH set to exactly the list in claude-tools.nix. The box cannot
# reach the host, so anything that needs it goes through the outbox: a
# directory the box can write and a host-side script (claude-outbox) reads.
{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  home = config.home.homeDirectory;
  wiki = "${home}/Documents/llm-wiki";
  repo = "${home}/nixos";
  outbox = "${home}/.local/state/claude-outbox";
  # Messages are written here, then renamed into the outbox, so the host
  # never reads a half-written file.
  outboxTmp = "${outbox}.tmp";
  boxCommitter = "claude-box";

  toolList = import ./claude-tools.nix {
    inherit pkgs;
    username = config.home.username;
  };
  claude = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
  srt = pkgs-unstable.sandbox-runtime;

  # Where the box may connect. WebFetch runs inside the box too, so a docs
  # site missing here is unreachable for it.
  allowedDomains = [
    # Claude itself: API, sign-in, connectors
    "api.anthropic.com"
    "*.anthropic.com"
    "claude.ai"
    "*.claude.ai"
    "*.claude.com"
    # code hosting
    "github.com"
    "*.github.com"
    "*.githubusercontent.com"
    # docs
    "nixos.org"
    "*.nixos.org"
    "docs.rs"
    "crates.io"
    "pypi.org"
    "*.npmjs.org"
    "developer.mozilla.org"
    "wiki.archlinux.org"
  ];

  # Claude's state: the only parts of ~/.claude the box can write. Its
  # settings, hooks and skills are symlinks, and a deny rule on a symlink does
  # not stop it being replaced, so ~/.claude is never writable as a whole.
  # ponytail: a new state dir in a future Claude version fails to write until
  # it is added here. ~/.claude.json is also not saved from the box (Claude
  # writes it by rename in $HOME); both only log an error.
  claudeState = map (n: "~/.claude/${n}") [
    "projects"
    "sessions"
    "session-env"
    "shell-snapshots"
    "file-history"
    "paste-cache"
    "plans"
    "debug"
    "cache"
    "state"
    "jobs"
    "backups"
    "downloads"
    "history.jsonl"
    ".credentials.json"
    "stats-cache.json"
    "cost-log.jsonl"
  ];

  # Read-only config, named one by one. Allowing ~/.claude as a whole gets
  # mounted over the writable state above and makes it read-only again.
  claudeConfig = map (n: "~/.claude/${n}") [
    "settings.json"
    "CLAUDE.md"
    "skills"
    "commands"
    "output-styles"
    "hooks"
    "plugins"
    "agents"
    "keybindings.json"
    "statusline-command.sh"
    "tts.conf"
    "tts-voice"
  ];

  srtSettings = pkgs.writeText "claude-box-srt.json" (builtins.toJSON {
    network = {
      inherit allowedDomains;
      deniedDomains = [];
    };
    filesystem = {
      # Home is hidden except what allowRead names. The rest are sockets:
      # nixpkgs' sandbox-runtime ships without the seccomp helper that blocks
      # Unix sockets, so the nix daemon, the session bus, Wayland and X11 are
      # hidden by path instead.
      denyRead = [
        "~"
        "/nix/var/nix/daemon-socket"
        "/run/user"
        "/run/dbus"
        "/tmp/.X11-unix"
      ];
      allowRead =
        [
          "."
          "~/.claude.json"
          "~/.config/git"
          wiki
          "${repo}/desktop/configs/claude" # what the ~/.claude symlinks point at
        ]
        ++ claudeConfig;
      allowWrite = ["." "/tmp" wiki outbox outboxTmp] ++ claudeState;
      # the launcher runs git in the wiki on the host afterwards, and git
      # runs the wiki's pre-commit hook (githooks/ -> scripts/check.py)
      denyWrite = ["${wiki}/.git/hooks" "${wiki}/.git/config" "${wiki}/githooks" "${wiki}/scripts"];
    };
  });

  # The box is the boundary, so the per-command Bash sandbox is off in both.
  noBashSandbox = pkgs.writeText "claude-no-bash-sandbox.json" (builtins.toJSON {sandbox.enabled = false;});

  # Prompt bar colour tells the two apart: the box blue, the host red. Claude
  # Code has no setting for it, only /color, so send that as the opening
  # prompt. It is saved per session, so a resume re-asserts this launcher's.
  # ponytail: only when no prompt of your own is given (a second positional
  # would clash), and not for a bare --resume, where it would become the
  # picker's search term.
  setColor = color: ''
    case "$*" in
      "" | -c | --continue | "--resume "* | "-r "*) set -- "$@" "/color ${color}" ;;
    esac
  '';

  boxPrompt = pkgs.writeText "claude-box-prompt.txt" ''
    This session runs inside a sandbox ("the box") that contains the whole Claude Code process.
    - Writable: the working directory, /tmp, the llm-wiki and Claude's own state. The rest of the home directory is hidden behind an empty scratch copy: a missing file there is not proof it does not exist, and anything written there is discarded when the session ends.
    - Unavailable: sudo, ssh, the nix daemon (so no nix build, nix shell or nix run), the session D-Bus, and any network host off the allowlist.
    - Missing a command? Run `claude-request-tool <nixpkgs-attribute> <one-line reason>`. Noah is notified; the tool exists after his next rebuild, in a new session. Do not look for a way around this.
    - llm-wiki: edit and commit as usual, but skip pull and push. The launcher syncs before and after the session.
    - Work that needs the host (rebuilds, the compositor, anything above): stop and tell Noah to continue with `claude-host --resume <this session id>`.
  '';

  boxGitConfig = pkgs.writeText "claude-box-gitconfig" ''
    [committer]
    	name = ${boxCommitter}
  '';

  # Inside the box these replace the real commands: each hands its input to
  # the host through the outbox.
  send = kind: ''
    f=$(mktemp ${outboxTmp}/${kind}.XXXXXXXX) && cat >"$f" && mv "$f" ${outbox}/
  '';
  boxCommands = [
    # The Stop hook's speech: the TTS daemon and the session bus are host-only.
    (pkgs.writeShellScriptBin "claude-speak" (send "speak"))
    (pkgs.writeShellScriptBin "claude-request-tool" ''
      if [ $# -lt 1 ]; then
        echo "usage: claude-request-tool <nixpkgs-attribute> [reason...]" >&2
        exit 2
      fi
      printf '%s\n%s\n' "$1" "''${*:2}" | { ${send "tool"} } || exit 1
      echo "Requested $1. Noah is notified; it is usable after his next rebuild, in a new session."
    '')
  ];

  hostLinks = skip:
    pkgs.runCommand "claude-host-links" {} ''
      mkdir -p $out/bin
      ${lib.concatStrings (lib.mapAttrsToList (dir: names: ''
          for n in ${toString (lib.subtractLists skip names)}; do ln -s ${dir}/$n $out/bin/$n; done
        '')
        toolList.fromHost)}
    '';
  mkTools = {
    extra ? [],
    skip ? [],
  }:
    pkgs.buildEnv {
      name = "claude-tools";
      paths = toolList.packages ++ extra ++ [(hostLinks skip)];
      pathsToLink = ["/bin"];
    };
  hostTools = mkTools {};
  boxTools = mkTools {
    extra = boxCommands;
    skip = ["claude-speak"];
  };

  git = "${pkgs.git}/bin/git";
  notify = "${pkgs.libnotify}/bin/notify-send -a Claude";
  sshQuick = "ssh -o ConnectTimeout=5 -o BatchMode=yes";

  boxed = pkgs.writeShellScriptBin "claude" ''
    if [ "$PWD" = "$HOME" ]; then
      echo "claude: the box makes the working directory writable, and that would be your whole home." >&2
      echo "        cd into a project first, or use claude-host." >&2
      exit 1
    fi
    mkdir -p ${outbox} ${outboxTmp}

    # Wiki sync happens out here: the box has no ssh keys and no route to the remote.
    wiki=${wiki}
    g() { ${git} -C "$wiki" "$@"; }
    if [ -d "$wiki/.git" ]; then
      GIT_SSH_COMMAND="${sshQuick}" g pull --ff-only --quiet ||
        echo "claude: wiki pull failed; continuing with the local copy" >&2
      before=$(g rev-parse HEAD)
    fi

    # srt write-protects these in the working directory by mounting over an
    # empty file it creates for each one that is missing. It removes them on
    # a normal exit but not on a hangup (closing the terminal), so note which
    # are missing now and remove exactly those on the way out.
    # ponytail: a SIGKILL of this launcher still leaves them behind.
    stubs=()
    for f in .bashrc .bash_profile .zshrc .zprofile .profile .gitconfig \
      .gitmodules .ripgreprc .mcp.json .idea .vscode .claude/agents .claude/commands; do
      [ -e "$f" ] || [ -L "$f" ] || stubs+=("$f")
    done
    [ -e .claude ] || stubs+=(.claude)
    clean_stubs() {
      for f in "''${stubs[@]}"; do
        if [ -d "$f" ]; then
          rmdir "$f" 2>/dev/null
        elif [ -f "$f" ] && [ ! -s "$f" ]; then
          rm -f "$f"
        fi
      done
    }
    trap clean_stubs EXIT
    trap 'exit 129' HUP TERM
    ${setColor "blue"}

    # Wiki commits made in the box carry committer "${boxCommitter}", which
    # is what `git log --committer=${boxCommitter}` and the lint skill audit.
    CLAUDE_BOXED=1 \
      GIT_CONFIG_COUNT=1 \
      GIT_CONFIG_KEY_0="includeIf.gitdir:$wiki/.path" \
      GIT_CONFIG_VALUE_0=${boxGitConfig} \
      PATH=${lib.makeBinPath [pkgs.bubblewrap pkgs.socat pkgs.ripgrep pkgs.coreutils pkgs.bash]} \
      ${srt}/bin/srt --settings ${srtSettings} -- \
      ${pkgs.coreutils}/bin/env PATH=${boxTools}/bin \
      ${claude}/bin/claude --settings ${noBashSandbox} \
      --append-system-prompt "$(cat ${boxPrompt})" "$@"
    rc=$?

    if [ -n "''${before:-}" ]; then
      # ponytail: with two sessions open this also sweeps up the other one's
      # uncommitted wiki edits, same as the SessionEnd hook always has.
      g add -A
      g diff --cached --quiet || GIT_COMMITTER_NAME=${boxCommitter} g commit -qm "wiki: autosave (boxed)"
      changed=$(g log --committer=${boxCommitter} --format='%s' "$before"..HEAD)
      if [ -n "$changed" ]; then
        GIT_SSH_COMMAND="${sshQuick}" g push --quiet || failed=" (push failed)"
        # librarian-run reports its own runs; only a failed push is news then
        if [ -z "''${LIBRARIAN_MAINT:-}" ] || [ -n "''${failed:-}" ]; then
          ${notify} "Boxed Claude changed the wiki''${failed:-}" "$changed"
        fi
      fi
    fi
    exit $rc
  '';

  unboxed = pkgs.writeShellScriptBin "claude-host" ''
    ${setColor "red"}
    # Agent teams (experimental) on the host only; the box keeps plain subagents.
    # auto: split panes when started inside tmux, in-process otherwise.
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
    PATH=${hostTools}/bin exec ${claude}/bin/claude --settings ${noBashSandbox} --teammate-mode auto "$@"
  '';

  # Runs on the host whenever the box leaves something in the outbox.
  # Nothing written by the box is ever executed or shown unsanitised: a tool
  # name must look like an attribute path and exist in nixpkgs, and the reason
  # is cut down to plain words before it goes into a comment.
  outboxScript = pkgs.writeShellApplication {
    name = "claude-outbox";
    runtimeInputs = with pkgs; [coreutils findutils gnugrep gnused gawk git libnotify alejandra systemd];
    text = ''
      # CLAUDE_TOOLS_REPO: for trying this from a worktree before it is merged.
      repo="''${CLAUDE_TOOLS_REPO:-${repo}}"
      list=desktop/modules/home/claude-tools.nix
      say() { notify-send -a Claude "$@"; }
      shopt -s nullglob

      for f in ${outbox}/speak.*; do
        /run/current-system/sw/bin/claude-speak <"$f" || true
        rm -f "$f"
      done

      for f in ${outbox}/tool.*; do
        attr=$(sed -n 1p "$f")
        reason=$(sed -n 2p "$f" | tr -cd 'A-Za-z0-9 ,.-' | cut -c1-80)
        rm -f "$f"

        if ! [[ $attr =~ ^[A-Za-z0-9_][A-Za-z0-9_.+-]*$ ]]; then
          say "Claude tool request rejected" "The name was not a valid nixpkgs attribute."
          continue
        fi
        if awk -v a="$attr" '$1 == a {found = 1} END {exit !found}' "$repo/$list"; then
          say "Claude asked for $attr" "Already on the list; it needs a rebuild or a new session."
          continue
        fi
        if ! /run/current-system/sw/bin/nix eval --raw --inputs-from "$repo/desktop" "nixpkgs#$attr.name" >/dev/null 2>&1; then
          say "Claude tool request rejected" "$attr is not a package in nixpkgs."
          continue
        fi

        sed -i "/# claude-outbox:insert/i $attr # requested by Claude: $reason" "$repo/$list"
        alejandra -q "$repo/$list"
        if git -C "$repo" commit -q -m "feat(claude): add $attr to claude tools" \
          -m "Requested from a boxed session: $reason" -- "$list"; then
          systemd-run --user --quiet --collect -- ${outboxRebuildPrompt}/bin/claude-outbox-rebuild-prompt "$attr" "$reason" "$repo"
        else
          git -C "$repo" checkout -q -- "$list"
          say "Claude tool request failed" "Could not commit $attr to claude-tools.nix."
        fi
      done

      # anything else in here would keep re-triggering the path unit
      find ${outbox} -mindepth 1 -delete
    '';
  };

  # Separate unit: the notification waits for a click and must not hold up
  # the queue.
  outboxRebuildPrompt = pkgs.writeShellApplication {
    name = "claude-outbox-rebuild-prompt";
    runtimeInputs = [pkgs.libnotify pkgs.bash];
    text = ''
      action=$(notify-send -a Claude -A rebuild=Rebuild "Claude added $1" "$2")
      if [ "$action" = rebuild ]; then
        # app-id matches the float rule in configs/niri/rules.kdl and umbriel/rules.toml
        # shellcheck disable=SC2016
        exec /etc/profiles/per-user/${config.home.username}/bin/ghostty --class=claude.rebuild -e bash -c \
          '"$1"/desktop/rebuild.sh; echo; read -rn1 -p "Press any key to close."' _ "$3"
      fi
    '';
  };
in {
  home.packages = [boxed unboxed];

  systemd.user.paths.claude-outbox = {
    Unit.Description = "Watch the boxed Claude's outbox";
    Path = {
      DirectoryNotEmpty = outbox;
      MakeDirectory = true;
    };
    Install.WantedBy = ["paths.target"];
  };
  systemd.user.services.claude-outbox = {
    Unit.Description = "Handle tool requests and speech from the boxed Claude";
    Service = {
      Type = "oneshot";
      ExecStart = "${outboxScript}/bin/claude-outbox";
    };
  };
}
