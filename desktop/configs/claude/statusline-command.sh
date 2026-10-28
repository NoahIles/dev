#!/usr/bin/env bash
# Claude Code status line: title | model | context used / window [bar]

input=$(cat)

model=$(jq -r '.model.display_name // "Unknown"' <<<"$input")
used=$(jq -r '.context_window.total_input_tokens // empty' <<<"$input")
size=$(jq -r '.context_window.context_window_size // empty' <<<"$input")
pct=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")

# Title: last /rename wins, else Claude's auto title (both live in the transcript)
title=""
if [ -f "$transcript" ]; then
  title=$(grep -h '"type":"custom-title"' "$transcript" | tail -1 | jq -r '.customTitle // empty')
  [ -z "$title" ] && title=$(grep -h '"type":"ai-title"' "$transcript" | tail -1 | jq -r '.aiTitle // empty')
fi

if [ -n "$used" ] && [ -n "$size" ] && [ -n "$pct" ]; then
  filled=$(awk -v p="$pct" 'BEGIN{printf "%d", p/10 + 0.5}')
  bar=$(printf '%*s' "$filled" '' | tr ' ' '#')$(printf '%*s' $((10 - filled)) '' | tr ' ' '-')
  ctx=$(awk -v u="$used" -v s="$size" -v p="$pct" 'BEGIN{printf "%.0fk / %.0fk (%.0f%%)", u/1000, s/1000, p}')
  ctx="$ctx [$bar]"
else
  ctx="- / - [----------]"
fi

printf "%s%s  |  %s" "${title:+$title  |  }" "$model" "$ctx"
