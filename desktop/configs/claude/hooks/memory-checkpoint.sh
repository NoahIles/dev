#!/usr/bin/env bash
# Stop hook: once per session, after real work, ask Claude to save memories
# before it stops. Agents rarely record lessons on their own mid-task; a
# checkpoint makes them (see the harness-engineering clipping in the wiki).
set -u

min_tools=20
input=$(cat)
command -v jq >/dev/null || exit 0
[ -d "$HOME/Documents/llm-wiki/memory/inbox" ] || exit 0
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = true ] && exit 0

session=$(jq -r '.session_id // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
[ -n "$session" ] && [ -f "$transcript" ] || exit 0

marker="${XDG_RUNTIME_DIR:-/tmp}/claude-memory-checkpoint/$session"
[ -e "$marker" ] && exit 0
[ "$(grep -o '"type":"tool_use"' "$transcript" | wc -l)" -ge "$min_tools" ] || exit 0
mkdir -p "$(dirname "$marker")" && touch "$marker"

jq -n --arg r "Memory checkpoint (once per session). Before stopping, check whether this session produced anything that meets the auto-memory bar: a correction or confirmed approach from Noah, a non-obvious gotcha, or a mistake of yours that could recur. Save each to the memory inbox now. If an existing memory already covers it, this is a repeat: note that in the memory, since a repeat is a promotion candidate. If nothing qualifies, stop without writing any text." \
  '{decision: "block", reason: $r}'
