# niri-scripts Reference

## niri msg — full command list

### Query commands (all support `--json` / `-j`)

| Command | Description |
|---------|-------------|
| `outputs` | All connected outputs with modes, current mode, logical position |
| `focused-output` | The currently focused output |
| `workspaces` | All workspaces with id, name, output, active state |
| `windows` | All open windows |
| `focused-window` | The focused window |
| `layers` | Open layer-shell surfaces (use to find `namespace` for layer-rules) |
| `keyboard-layouts` | Configured keyboard layouts |
| `overview-state` | Whether the overview is open |
| `casts` | Active PipeWire screencasts |
| `version` | Running niri version |

### niri msg output \<OUTPUT\> \<ACTION\>

OUTPUT = port name e.g. `DP-1`, `HDMI-A-1` (from `niri msg outputs`)

| Action | Example |
|--------|---------|
| `on` / `off` | `niri msg output "DP-2" off` |
| `mode <WxH@Hz>` | `niri msg output "DP-1" mode "3440x1440@120"` |
| `scale <factor>` | `niri msg output "DP-1" scale 1.5` |
| `transform <t>` | `niri msg output "DP-1" transform 90` |
| `position x=<x> y=<y>` | `niri msg output "DP-2" position x=3440 y=0` |
| `vrr on\|off\|on-demand` | `niri msg output "DP-1" vrr on-demand` |

All output changes are **runtime-only** — not written to config.kdl.

### niri msg action — key actions for scripts

| Action | Notes |
|--------|-------|
| `load-config-file` | Reload `~/.config/niri/config.kdl` |
| `spawn -- cmd arg…` | Spawn process directly |
| `spawn-sh "cmd"` | Spawn via shell |
| `close-window` | Close focused window |
| `focus-window --id <id>` | Focus by window id |
| `focus-monitor --output <name>` | Focus a specific monitor |
| `move-window-to-monitor --output <name>` | Move focused window |
| `move-column-to-workspace --reference <name\|idx>` | Move column |
| `power-off-monitors` / `power-on-monitors` | DPMS |
| `toggle-overview` | Open/close the overview |
| `screenshot` / `screenshot-screen` / `screenshot-window` | Screenshot |
| `toggle-window-floating` | Float/tile focused window |

### JSON schemas (key fields)

**focused-window / windows[]**
```
id, app_id, title, pid, workspace_id,
is_focused, is_floating, is_urgent,
focus_timestamp, layout
```

**outputs{}** (keyed by port name)
```
name, make, model, serial, physical_size[w,h],
modes[{width,height,refresh_rate,is_preferred}],
current_mode (index or null if off),
logical {x,y,width,height,scale,transform} (null if off),
vrr_supported, vrr_enabled, is_custom_mode
```

**workspaces[]**
```
id, name, output, active_window_id,
is_focused, is_active
```

---

## noctalia msg — full command list

### Bar & Dock

```
bar-show / bar-hide / bar-toggle [bar-name] [monitor-selector]
bar-auto-hide-set <on|off> [bar-name] [monitor-selector]
dock-show / dock-hide / dock-toggle
dock-reload
```

### Volume & Audio

```
volume-up [step]
volume-down [step]
volume-set <value>
volume-mute
mic-volume-up [step]
mic-volume-down [step]
mic-volume-set <value>
mic-mute
media <next|previous|toggle|stop>
```

### Brightness

```
brightness-up [monitor-selector] [step]
brightness-down [monitor-selector] [step]
brightness-set <value> | brightness-set [monitor-selector] <value>
brightness-osd <value>
```

Monitor selector: `current` (default), `*` / `all`, or connector name.

### Wallpaper

```
wallpaper-get [connector]
wallpaper-set [connector] <path>
wallpaper-random [connector]
```

### Theme & Night Light

```
theme-mode-get
theme-mode-set <dark|light|auto>
theme-mode-toggle
nightlight-enable / nightlight-disable
nightlight-force-toggle
color-scheme-get
color-scheme-set <source> <name>
templates-apply
```

### Notifications & DND

```
notification-dnd-toggle
notification-dnd-set <on|off>
notification-dnd-status
notification-clear-active
notification-clear-history
```

### Power & Session

```
session <lock|suspend|lock-and-suspend|logout|reboot|shutdown>
power-cycle
power-set <performance|balanced|power-saver>
dpms-off / dpms-on
caffeine-enable / caffeine-disable / caffeine-toggle
```

### Network & Connectivity

```
wifi-enable / wifi-disable / wifi-toggle / wifi-status
bluetooth-enable / bluetooth-disable / bluetooth-toggle / bluetooth-status
```

### Panels & Settings

```
panel-open <id> [context]
panel-close [id]
panel-toggle <id> [context]
settings-toggle
```

Common panel ids: `launcher`, `clipboard`, `control-center`, `notifications`

### Misc

```
screenshot-region
screenshot-fullscreen [pick|monitor|all]
status                         # print full state as JSON
config-reload
greeter-sync
scripted-widget <name> <target[:bar-name]> <event> [payload]
```
