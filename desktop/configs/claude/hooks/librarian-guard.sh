#!/usr/bin/env bash
# PreToolUse guard for the librarian agent (agents/librarian.md).
#   reference mode (default): may write only the queue file; Bash is
#     read-only git.
#   resolve (LIBRARIAN_RESOLVE=1, set by librarian-prompt): no limits;
#     Noah is at the keyboard approving each step.
#   maintenance (LIBRARIAN_MAINT=1): may write inside the wiki except the
#     files that run on the host or load into every session; Bash is git
#     (no push, no config) and the wiki checker.
# Exit 2 blocks the call and shows stderr to the agent.
set -u
input=$(cat)
wiki="$HOME/Documents/llm-wiki"
queue="$wiki/memory/librarian-queue.md"
maint="${LIBRARIAN_MAINT:-}"
deny() {
  echo "librarian-guard: $*" >&2
  exit 2
}

# Resolve mode: Noah clicked Resolve and approves each step himself.
[ "${LIBRARIAN_RESOLVE:-}" = 1 ] && exit 0

tool=$(jq -r '.tool_name' <<<"$input")
case "$tool" in
Edit | Write | NotebookEdit)
  path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
  path=$(realpath -m -- "$path")
  if [ "$maint" != 1 ]; then
    [ "$path" = "$queue" ] || deny "reference mode may only write $queue"
    exit 0
  fi
  case "$path" in
  "$wiki"/scripts/* | "$wiki"/githooks/* | "$wiki"/.git/* | */CLAUDE.md | \
    "$wiki"/wiki/personal/working-with-noah.md)
    deny "$path is Noah's to change; draft a patch under .librarian/drafts/ and escalate"
    ;;
  "$wiki"/*) exit 0 ;;
  *) deny "only the wiki is writable" ;;
  esac
  ;;
Bash)
  cmd=$(jq -r '.tool_input.command' <<<"$input")
  # one plain command: no chaining, pipes, redirects or substitution
  case "$cmd" in
  *';'* | *'&'* | *'|'* | *'>'* | *'<'* | *'`'* | *'$('* | *$'\n'*)
    deny "one plain command at a time, no chaining, pipes or redirects"
    ;;
  esac
  case "$cmd" in
  "git "*" -c "* | "git -c "* | "git "*config* | "git "*push*)
    deny "no git config or push; the launcher syncs the wiki"
    ;;
  "git log"* | "git show"* | "git diff"* | "git grep"* | "git blame"* | "git status"*)
    exit 0
    ;;
  esac
  [ "$maint" = 1 ] || deny "reference mode: read-only git only"
  case "$cmd" in
  "git add"* | "git commit"* | "git mv"* | "git rm"* | "python3 scripts/check.py" | "date"* | "ls"* | "mkdir -p .librarian/drafts")
    exit 0
    ;;
  esac
  deny "not allowed: $cmd"
  ;;
esac
exit 0
