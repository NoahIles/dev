---
name: audio-routing
description: Diagnose and permanently fix per-application audio routing on Noah's PipeWire/WirePlumber setup. Use when an app keeps landing on the wrong sink, forgets its pavucontrol device selection, or needs to be pinned to a specific Rode virtual sink (Game/Music/A/B). Follows a diagnose-first workflow — the fix depends on how the app's stream connects.
---

# Audio Routing (PipeWire / WirePlumber)

Noah's sinks (`pactl list sinks short`): `Rode_Main_Output`, `Rode_Game_Out`
(games), `Rode_Music_Out` (default), `Rode_A_Out`, `Rode_B_Out` — virtual sinks
defined in `~/.config/pipewire/pipewire.conf.d/99-rodecaster-virtual-sinks.conf`.

Core principle: **diagnose before fixing.** Apps disrespect device selection
for different reasons; the fix depends on *why*. Worked example (Minecraft):
`~/Documents/llm-wiki/wiki/linux/minecraft-audio-routing.md`.

## Step 1 — Diagnose: how does the stream connect?

With the app running and making sound:

```bash
# Find the stream node and its key props
pw-dump | jq '.[] | select(.type=="PipeWire:Interface:Node" and .info.props."media.class"=="Stream/Output/Audio") | .info.props | {id: ."object.id", "node.name", "application.name", "client.api", "target.object", "node.loop.name", "media.role"}'

# Which sink is it actually on
pactl list sink-inputs | grep -E 'Sink Input #|Sink:|node.name|application.name'
```

Decision table:

| Observation | Meaning |
|---|---|
| `client.api: "pipewire-pulse"` | pulse client — `PULSE_SINK` env and stream-restore memory work |
| No `client.api`, custom loop name (e.g. `ALSoftP0`) | native PipeWire client — pulse-layer tools are irrelevant |
| `target.object` set in the node's own props | **app pins its device at connect** — this is the usual culprit. WirePlumber honors node-defined targets AND refuses to save/restore manual moves for them |
| No `target.object`, still forgets moves | check restore-stream state (below) — key mismatch or volume-only entry |

```bash
# What WirePlumber remembers (well-behaved apps get a "target": entry here)
grep -E '<application.name or node.name>' ~/.local/state/wireplumber/stream-properties
```

## Step 2 — Fix ladder (stop at the first rung that holds)

1. **In-app device setting** — if the app has one and it persists, use it.
   (Rejected for Minecraft only because it's per-Prism-instance.)
2. **Move it once and check it's remembered** — if the stream has no pinned
   target, WirePlumber restore-stream saves the move keyed on
   `application.name`. Done — this is how all Steam games work.
3. **`PULSE_SINK=<sink_name>` env** — only if the stream is a pulse client
   (`client.api: pipewire-pulse`) AND the app doesn't explicitly name a device.
   Scope it via a `.desktop` override in `~/.local/share/applications/` with
   `Exec=env PULSE_SINK=... <binary>`. Caveat: terminal launches and
   already-running single-instance daemons bypass it.
4. **WirePlumber linking hook** — for apps that pin `target.object` themselves
   (OpenAL-soft, some game engines). Works for any client API, any launch
   method. Template below.

## Known dead ends — do not retry

- WirePlumber `node.rules` config key: **does not exist**, silent no-op.
- pipewire-pulse `pulse.rules` → `update-props { target.object }`: rules apply
  (verifiable with a marker prop) but pipewire-pulse writes the client's
  explicitly-requested device *after* rules run. Unbeatable at that layer.
- `PULSE_SINK` against an app that names its device explicitly: app-specified
  device beats the env in libpulse. OpenAL-soft does this even on its pulse
  backend (`ALSOFT_DRIVERS=pulse`), and `allow-moves=true` doesn't stop it.
- `speaker-test` as a verification tool: uses ALSA directly, not pulse —
  invalid test for `PULSE_SINK`. Use `paplay` instead.

## WirePlumber linking hook (rung 4)

Working example: `~/.local/share/wireplumber/scripts/linking/route-java-to-game.lua`
(routes `node.name == "java"` → `Rode_Game_Out`) plus loader
`~/.config/wireplumber/wireplumber.conf.d/60-route-java-to-game.conf`.

For a new app, copy that script, change the match (`node.name` /
`application.name` from Step 1) and the target sink, and add a loader conf:

```
wireplumber.components = [
  { name = linking/<script>.lua, type = script/lua, provides = custom.<name> }
]
wireplumber.profiles = { main = { custom.<name> = required } }
```

Structure to preserve when adapting the script (modeled on stock
`/usr/share/wireplumber/scripts/linking/find-defined-target.lua`):
- Hook `select-target` events, `before = "linking/find-defined-target"`.
- Bail if a target is already picked, if props don't match, or if default
  metadata has `target.object`/`target.node` for the node — **this is what
  keeps manual pavucontrol moves working; never remove it.**
- Find the sink via `om:iterate { type = "SiLinkable" }` matching `node.name`
  + `item.node.direction == "input"` + `lutils.canLink`.
- Set `si_flags` (`has_node_defined_target`, `can_passthrough`,
  `has_defined_target`) and `event:set_data ("target", target)`.

Gotchas:
- Scripts MUST live in `~/.local/share/wireplumber/scripts/` —
  `~/.config/wireplumber/scripts/` is not searched; a missing required script
  puts wireplumber.service in a restart loop ("Could not locate script").
- After changes: `systemctl --user restart wireplumber`, then check
  `journalctl --user -u wireplumber -n 10` for load errors before testing.

## Step 3 — Verify

1. Fully quit and relaunch the app (config reloads don't re-trigger linking).
2. `pactl list sink-inputs | grep -B30 '<match>' | grep 'Sink:'` — compare the
   sink index against `pactl list sinks short`.
3. Manually move the stream (`pactl move-sink-input <id> <other_sink>`) and
   confirm it sticks — the hook must not fight manual moves.

Testing gotchas: `pkill -f <name>` can match your own shell wrapper and kill
the compound command — use `pkill -x`. Launch detached with
`setsid <app> >log 2>&1 & disown`, then poll for the stream in a sleep loop.
