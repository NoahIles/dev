---
name: niri-scripts
description: Write or edit bash scripts that interact with the niri Wayland compositor or Noctalia desktop shell via their IPC APIs. Use when writing scripts in ~/.config/niri/scripts/, when the task involves `niri msg` or `noctalia msg` commands, or when automating compositor behavior (outputs, windows, workspaces, bar/dock, wallpaper, volume, notifications).
---

# Niri Scripts

## Conventions

- Shebang: `#!/usr/bin/env bash`
- Location: `~/.config/niri/scripts/` — make executable with `chmod +x`
- State files: `/tmp/niri-<script-name>` for toggle state
- User selection: `fuzzel --dmenu --prompt "label: "`
- Notifications: `notify-send` (supports `--action` for interactive buttons)
- Clipboard: `wl-copy` / `wl-paste`

## niri IPC quick reference

```bash
# Query (all support -j / --json flag)
niri msg outputs                        # list all outputs
niri msg focused-output                 # focused output info
niri msg focused-window                 # focused window info
niri msg workspaces                     # all workspaces
niri msg windows                        # all open windows
niri msg layers                         # layer-shell surfaces

# Actions
niri msg action load-config-file        # reload niri config
niri msg action spawn-sh "cmd"          # run shell command
niri msg action close-window
niri msg action focus-window --id <id>
niri msg action move-window-to-workspace --reference <name|index>

# Output control (runtime, not persisted to config)
niri msg output "DP-1" on
niri msg output "DP-1" off
niri msg output "DP-1" mode "1920x1080@60"
niri msg output "DP-1" scale 1.5
niri msg output "DP-1" vrr on
```

## Noctalia IPC quick reference

```bash
# Bar / dock
noctalia msg bar-show / bar-hide / bar-toggle [bar-name] [monitor-selector]
noctalia msg dock-show / dock-hide / dock-toggle

# Volume / brightness
noctalia msg volume-up / volume-down / volume-mute
noctalia msg brightness-up / brightness-down [monitor-selector]

# Wallpaper
noctalia msg wallpaper-random [connector]
noctalia msg wallpaper-set [connector] <path>
noctalia msg wallpaper-get [connector]

# Theme / night light
noctalia msg nightlight-enable / nightlight-disable / nightlight-force-toggle
noctalia msg theme-mode-set dark|light|auto

# Session
noctalia msg session lock|suspend|logout|reboot|shutdown

# Notifications
noctalia msg notification-dnd-toggle
noctalia msg notification-clear-active
```

Full command listings: see [REFERENCE.md](REFERENCE.md)

## Common jq patterns

```bash
# Get active output names (current_mode != null)
niri msg --json outputs | jq -r 'to_entries[].value | select(.current_mode != null) | .name'

# Display name (Make Model) for fuzzel
niri msg --json outputs | jq -r 'to_entries[].value | "\(.make) \(.model)"'

# Reverse-lookup port name from display name
niri msg --json outputs | jq -r --arg n "$selected" \
  'to_entries[].value | select((.make + " " + .model) == $n) | .name'

# Focused window app-id and pid
niri msg --json focused-window | jq -r '.app_id, .pid'

# Windows on a specific workspace (workspace_id is a NUMBER — use --argjson)
niri msg --json windows | jq -r --argjson ws 4 '.[] | select(.workspace_id == $ws) | .title'

# Focused workspace id
niri msg --json workspaces | jq '.[] | select(.is_focused) | .id'

# Column count on a workspace (1-indexed columns; floating windows excluded)
niri msg --json windows | jq --argjson ws 4 \
  '[.[] | select(.workspace_id == $ws and .is_floating == false)
        | .layout.pos_in_scrolling_layout[0]] | max // 0'
```

## Gotchas

- **Output names contain spaces** — always quote: `niri msg output "$port" on`
- **`niri msg output` changes are runtime-only** — not persisted to config.kdl; use `niri msg action load-config-file` after editing config.kdl instead
- **Reload config vs output toggle** — prefer `niri msg output` for temporary changes, edit config.kdl + `niri msg action load-config-file` for permanent ones
- **`jq -r`** — always use for string values destined for shell variables (strips JSON quotes)
- **`--arg` in jq** — use for safe shell-variable interpolation inside jq filters
- **`noctalia msg` has no `--json` flag** — status commands print plain text
- **Column actions only hit the focused column** — `set-column-width`, `expand-column-to-available-width` etc. take no `--id` (only `focus-window --id` does). To touch every column, loop `focus-column <N>` → action, then restore focus with `focus-window --id "$saved"`
- **`.layout.pos_in_scrolling_layout` = `[column, row]`, 1-indexed** — `null` for floating windows, so filter `is_floating == false`. It's the only way to recover column grouping; the IPC has no column objects
- **Proportional widths already account for gaps** — `set-column-width "33%"` × 3 fits exactly on a 3-column workspace; don't subtract gaps yourself
- **`min-width` window rules silently win** — a column that can't shrink pushes the others offscreen
