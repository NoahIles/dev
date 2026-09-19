#!/usr/bin/env bash
# Claude Code status line script
# Shows: model name | context progress bar | session cost | 12h cost

input=$(cat)

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# --- Context window ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

if [ -n "$used_pct" ] && [ -n "$total_input" ] && [ -n "$ctx_size" ]; then
  bar_len=10
  filled=$(echo "$used_pct $bar_len" | awk '{printf "%d", int($1 / 100 * $2 + 0.5)}')
  empty=$((bar_len - filled))
  bar=""
  for i in $(seq 1 "$filled"); do bar="${bar}#"; done
  for i in $(seq 1 "$empty");  do bar="${bar}-"; done
  # Format numbers with commas
  used_fmt=$(printf "%'d" "$total_input" 2>/dev/null || echo "$total_input")
  size_fmt=$(printf "%'d" "$ctx_size" 2>/dev/null || echo "$ctx_size")
  ctx_str="${used_fmt} / ${size_fmt} [${bar}]"
else
  ctx_str="- / - [----------]"
fi

# --- Cost calculation ---
# Pricing (per million tokens):
#   Input:               $3.00
#   Output:             $15.00
#   Cache write:         $3.75
#   Cache read:          $0.30

cost_session=$(echo "$input" | jq -r '
  .context_window |
  if .current_usage == null then
    "?"
  else
    (
      (.total_input_tokens // 0)          * 3.00    / 1000000 +
      (.total_output_tokens // 0)         * 15.00   / 1000000 +
      (.current_usage.cache_creation_input_tokens // 0) * 3.75 / 1000000 +
      (.current_usage.cache_read_input_tokens // 0)     * 0.30 / 1000000
    ) | . * 1000 | round | . / 1000 | tostring |
    if test("\\.") then
      (split(".") | .[0] + "." + (.[1] + "000")[0:3])
    else
      . + ".000"
    end |
    "$" + .
  end
')

# --- 12-hour rolling cost log ---
cost_log="$HOME/.claude/cost-log.jsonl"
session_id=$(echo "$input" | jq -r '.session_id // ""')
now_epoch=$(date +%s)
cutoff=$((now_epoch - 43200))  # 12 hours ago

# Record current session cost (only if we have a real value)
if [ "$cost_session" != "?" ] && [ -n "$session_id" ]; then
  raw_cost=$(echo "$input" | jq -r '
    .context_window |
    if .current_usage == null then "" else
      (
        (.total_input_tokens // 0)          * 3.00    / 1000000 +
        (.total_output_tokens // 0)         * 15.00   / 1000000 +
        (.current_usage.cache_creation_input_tokens // 0) * 3.75 / 1000000 +
        (.current_usage.cache_read_input_tokens // 0)     * 0.30 / 1000000
      ) | tostring
    end
  ')
  if [ -n "$raw_cost" ]; then
    # Write/update this session's cost entry (one line per session_id)
    tmp_log="${cost_log}.tmp.$$"
    touch "$cost_log"
    # Remove old entry for this session, then append updated one
    grep -v "\"session_id\":\"${session_id}\"" "$cost_log" > "$tmp_log" 2>/dev/null || true
    echo "{\"session_id\":\"${session_id}\",\"epoch\":${now_epoch},\"cost\":${raw_cost}}" >> "$tmp_log"
    mv "$tmp_log" "$cost_log"
  fi
fi

# Sum costs from sessions active within the last 12 hours
cost_12h="$0.000"
if [ -f "$cost_log" ]; then
  cost_12h=$(awk -v cutoff="$cutoff" '
    BEGIN { total = 0 }
    {
      # extract epoch and cost with simple field extraction
      if (match($0, /"epoch":([0-9]+)/, ep) && match($0, /"cost":([0-9.eE+\-]+)/, co)) {
        if (ep[1] + 0 >= cutoff) {
          total += co[1] + 0
        }
      }
    }
    END { printf "$%.3f", total }
  ' "$cost_log" 2>/dev/null || echo '$0.000')
fi

# --- Claude.ai rate limits ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

limits_str=""
if [ -n "$five_pct" ]; then
  limits_str="5h:$(printf '%.0f' "$five_pct")%"
fi
if [ -n "$week_pct" ]; then
  week_fmt="7d:$(printf '%.0f' "$week_pct")%"
  if [ -n "$limits_str" ]; then
    limits_str="${limits_str} ${week_fmt}"
  else
    limits_str="$week_fmt"
  fi
fi

# --- Assemble output ---
if [ -n "$limits_str" ]; then
  printf "%s  |  %s  |  %s  |  session: %s  |  12h: %s" \
    "$model" "$ctx_str" "$limits_str" "$cost_session" "$cost_12h"
else
  printf "%s  |  %s  |  session: %s  |  12h: %s" \
    "$model" "$ctx_str" "$cost_session" "$cost_12h"
fi
