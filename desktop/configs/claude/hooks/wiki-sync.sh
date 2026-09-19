#!/usr/bin/env bash
# Keeps the llm-wiki in sync around Claude Code sessions.
#   start (SessionStart): report last push failure, pull, expire the Archive,
#                         nudge when the Inbox index nears its load limit.
#                         Anything printed here lands in Claude's context.
#   end   (SessionEnd):   Autosave whatever was left uncommitted, then push.
# Claude still commits each edit itself; this only catches leftovers.
set -u

wiki="$HOME/Documents/llm-wiki"
marker="${XDG_STATE_HOME:-$HOME/.local/state}/claude-wiki-sync-failed"
[ -d "$wiki/.git" ] || exit 0
export GIT_SSH_COMMAND="ssh -o ConnectTimeout=5 -o BatchMode=yes"
g() { git -C "$wiki" "$@"; }

case "${1:-}" in
start)
  if [ -f "$marker" ]; then
    echo "llm-wiki: last session's autosave/push failed — check the wiki repo:"
    cat "$marker"
    rm -f "$marker"
  fi

  if ! out=$(g pull --ff-only --quiet 2>&1); then
    echo "llm-wiki: pull failed, resolve by hand (never auto-merge):"
    echo "$out"
  fi

  # Retention: 6 months, by the month folder a Memory was archived into.
  # ponytail: plain rm — the next Autosave commits the deletion.
  cutoff=$(date -d '6 months ago' +%Y-%m)
  for dir in "$wiki"/memory/archive/*/; do
    [ -d "$dir" ] || continue
    month=$(basename "$dir")
    [[ "$month" < "$cutoff" ]] && rm -rf "$dir"
  done

  index="$wiki/memory/inbox/MEMORY.md"
  if [ -f "$index" ]; then
    lines=$(wc -l <"$index")
    if [ "$lines" -gt 150 ]; then
      echo "llm-wiki: memory Inbox index is $lines lines (only 200 load). Suggest running the llm-wiki-lint skill to promote memories."
    fi
  fi
  ;;
end)
  mkdir -p "$(dirname "$marker")"
  {
    g add -A &&
      { g diff --cached --quiet || g commit -qm "wiki: autosave"; } &&
      g push --quiet
  } >/dev/null 2>"$marker.err" || {
    { date -Is; cat "$marker.err"; } >"$marker"
  }
  rm -f "$marker.err"
  ;;
esac
exit 0
