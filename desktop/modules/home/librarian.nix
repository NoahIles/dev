# The llm-wiki librarian's maintenance loop (host side).
# Agent: configs/claude/agents/librarian.md. Design and plan:
# docs/superpowers/{specs,plans}/2026-11-14-llm-wiki-librarian*.md.
#
# Every 15 min the timer runs librarian-run, which exits quietly unless the
# wiki has debt (librarian-score >= threshold), is clean and has been quiet
# for 30 min. Then it collects live facts, runs the boxed librarian headless
# and, if the run escalated anything new, sends one notification whose button
# resumes that session. Everything here lives in ~/nixos on purpose: the
# librarian can commit to the wiki, so no wiki file is ever run from here
# (scripts/check.py excepted: it is the wiki's own pre-commit hook, and the
# box can't write it).
{
  config,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  wiki = "${home}/Documents/llm-wiki";
  state = "${home}/.local/state/librarian";
  bin = "/etc/profiles/per-user/${config.home.username}/bin";
  threshold = 10; # back-tested 2026-10-15..11-14: wakes every few days, and after big sessions
  quietMinutes = 30;

  # Debt since the last run (or the last lint: commit before the first run):
  # wiki pages changed + memories added + 2 per open queue line.
  score = pkgs.writeShellApplication {
    name = "librarian-score";
    runtimeInputs = with pkgs; [git gnugrep coreutils];
    text = ''
      cd ${wiki}
      base=$(cat ${state}/last-head 2>/dev/null || git log -1 --grep='^lint:' --format=%H)
      git cat-file -e "$base^{commit}" 2>/dev/null || base=$(git rev-list --max-parents=0 HEAD | tail -1)
      pages=$(git diff --name-only "$base" HEAD -- wiki | wc -l)
      mems=$(git diff --name-only --diff-filter=A "$base" HEAD -- memory/inbox | grep -vc MEMORY.md || true)
      queue=$(grep '^- ' memory/librarian-queue.md 2>/dev/null | grep -vc '\[escalated\]' || true)
      echo $((pages + mems + 2 * queue))
    '';
  };

  run = pkgs.writeShellApplication {
    name = "librarian-run";
    runtimeInputs = with pkgs; [git jq coreutils gnugrep gnused systemd libnotify score];
    text = ''
      cd ${wiki}
      mkdir -p ${state} .librarian
      force=''${1:-}
      s=$(librarian-score)
      if [ "$force" != --force ]; then
        [ "$s" -ge ${toString threshold} ] || exit 0
        # A dirty tree means a session is mid-edit; the boxed launcher would
        # sweep its edits into the librarian's commit.
        [ -z "$(git status --porcelain)" ] || { echo "wiki dirty, skipping (score $s)"; exit 0; }
        last=$(git log -1 --format=%ct)
        [ $(($(date +%s) - last)) -ge $((${toString quietMinutes} * 60)) ] || exit 0
      fi
      echo "score $s >= ${toString threshold}, running"

      # Live facts the box can't see, read-only.
      {
        echo "# Live facts, collected $(date -Is) by librarian-run"
        echo; echo "## ~/nixos"; echo '```'
        git -C ${home}/nixos log --oneline -8
        echo; git -C ${home}/nixos branch --format='%(refname:short) %(objectname:short) %(committerdate:short)'
        echo; git -C ${home}/nixos worktree list
        echo; git -C ${home}/nixos status --short | head -20
        echo '```'
        echo; echo "## System"; echo '```'
        echo "generation: $(readlink /nix/var/nix/profiles/system)"
        echo "kernel: $(uname -r)"
        echo "failed system units:"; systemctl --failed --no-legend --plain || true
        echo "failed user units:"; systemctl --user --failed --no-legend --plain || true
        echo '```'
      } >.librarian/facts.md

      out=$(mktemp)
      LIBRARIAN_MAINT=1 ${bin}/claude --agent librarian --model sonnet \
        --permission-mode acceptEdits \
        --allowedTools 'Bash(git:*)' 'Bash(python3 scripts/check.py)' 'Bash(echo:*)' 'Bash(ls:*)' 'Bash(date:*)' 'Bash(mkdir:*)' \
        --output-format json \
        -p "Maintenance run. Debt score $s. Follow your maintenance-mode instructions." \
        </dev/null >"$out" || echo "librarian exited $?"
      git rev-parse HEAD >${state}/last-head

      res=$(jq -c 'if type == "array" then .[-1] else . end' "$out" 2>/dev/null || echo '{}')
      rm -f "$out"
      sid=$(jq -r '.session_id // empty' <<<"$res")
      text=$(jq -r '.result // empty' <<<"$res")
      echo "session $sid cost \$$(jq -r '.total_cost_usd // "?"' <<<"$res")"
      printf '%s\n' "$text"

      items=$(sed -n '/^```escalations/,/^```/{/^```/d;p}' <<<"$text" | sed '/^\s*$/d')
      touch ${state}/seen
      new=$(grep -vxFf ${state}/seen <<<"$items" || true)
      [ -n "$new" ] && [ -n "$sid" ] || exit 0
      printf '%s\n' "$new" >>${state}/seen
      launcher=claude
      grep -q 'nixos' <<<"$new" && launcher=claude-host
      # Detached, so waiting for the click doesn't hold this unit open.
      systemd-run --user --collect --no-block --unit="librarian-prompt-$sid" \
        ${prompt}/bin/librarian-prompt "$sid" "$launcher" "$(wc -l <<<"$new") item(s)" "$new"
    '';
  };

  prompt = pkgs.writeShellApplication {
    name = "librarian-prompt";
    runtimeInputs = [pkgs.libnotify pkgs.bash];
    text = ''
      action=$(notify-send -a Librarian -w -A resume=Resolve "Librarian needs you: $3" "$4")
      if [ "$action" = resume ]; then
        # app-id matches the float rule in configs/niri/rules.kdl and umbriel/rules.toml
        # shellcheck disable=SC2016
        exec ${bin}/ghostty --class=claude.rebuild --working-directory=${wiki} \
          -e bash -c 'cd "$1" && exec "$2" --resume "$3"' _ ${wiki} "${bin}/$2" "$1"
      fi
    '';
  };
in {
  home.packages = [score run];

  systemd.user.timers.librarian = {
    Unit.Description = "Wake the llm-wiki librarian when the wiki has debt";
    Timer = {
      OnCalendar = "*:0/15";
      Persistent = false;
    };
    Install.WantedBy = ["timers.target"];
  };
  systemd.user.services.librarian = {
    Unit.Description = "llm-wiki librarian maintenance run (gated by librarian-score)";
    Service = {
      Type = "oneshot";
      ExecStart = "${run}/bin/librarian-run";
      TimeoutStartSec = "30min";
    };
  };
}
