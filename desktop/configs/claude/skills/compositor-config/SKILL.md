---
name: niri-config
description: Edit Noah's niri Wayland compositor config safely. Use when asked to add or modify window rules, layer rules, keybindings, layout settings, or any other niri configuration. Always fetches relevant niri wiki docs before making changes and validates with `niri validate` after every edit.
---

# Niri Config

## Config location

`/home/noah/.config/niri/` — split across:
- `config.kdl` — top-level, includes all others
- `rules.kdl` — window-rule and layer-rule blocks
- `keybinds.kdl` — keyboard shortcuts
- `exec.kdl` — autostart programs
- `noctalia.kdl` — noctalia bar/panel config

## Workflow

1. **Fetch docs first** — before touching any rule/property, fetch the relevant wiki page (see URLs below). Niri's property set changes across releases; never guess from memory.
2. **Make the edit** — prefer editing the most specific file (e.g. `rules.kdl` for rules).
3. **Validate** — always run `niri validate` after every change. Fix any errors before reporting done.

```bash
niri validate
```

## Key docs URLs

| Topic | URL |
|-------|-----|
| Window Rules | https://github.com/YaLTeR/niri/wiki/Configuration:-Window-Rules |
| Layer Rules | https://github.com/YaLTeR/niri/wiki/Configuration:-Layer-Rules |
| Layout | https://github.com/YaLTeR/niri/wiki/Configuration:-Layout |
| Outputs | https://github.com/YaLTeR/niri/wiki/Configuration:-Outputs |
| Named Workspaces | https://github.com/YaLTeR/niri/wiki/Configuration:-Named-Workspaces |
| Fullscreen & Maximize | https://github.com/YaLTeR/niri/wiki/Fullscreen-and-Maximize |

## Common gotchas

- **`gaps` is layout-only** — not available in `window-rule`. Per-window gap control doesn't exist; use `open-maximized-to-edges true` to strip gaps/borders/struts, or a named workspace with `layout { gaps 0 }`.
- **`match` lines are OR'd** — multiple `match` lines in one block match any of them, not all.
- **Opening vs dynamic properties** — `open-*` properties apply once on open; others (opacity, blur, etc.) apply continuously.
- **`niri validate` is the source of truth** — don't report a change as done until it passes.
- **Layer rules match by namespace** — use `niri msg layers` to find the namespace of a surface.

## window-rule properties (key subset)

Opening (once): `default-column-width`, `default-window-height`, `open-on-output`, `open-on-workspace`, `open-maximized`, `open-maximized-to-edges`, `open-fullscreen`, `open-floating`, `open-focused`

Dynamic: `opacity`, `variable-refresh-rate`, `draw-border-with-background`, `focus-ring`, `border`, `shadow`, `geometry-corner-radius`, `clip-to-geometry`, `background-effect`, `block-out-from`, `scroll-factor`, `min-width`, `max-width`, `min-height`, `max-height`

## layer-rule properties

`opacity`, `shadow`, `geometry-corner-radius`, `block-out-from`, `place-within-backdrop`, `baba-is-float`, `background-effect`, `popups`

Layer match conditions: `namespace` (regex), `at-startup` (bool), `layer` ("background"|"bottom"|"top"|"overlay")

## Session end — skill self-improvement

After completing the user's niri config task, always close the session by grilling the user with these questions. Ask them all at once in a single message:

1. **Missing properties** — Did you need any window-rule or layer-rule properties that weren't listed in this skill? Any you had to look up manually?
2. **New gotchas** — Did you run into any surprising behavior or errors that aren't in the Common Gotchas section?
3. **Workflow friction** — Was there any step in the workflow that felt slow, wrong, or awkward?
4. **Missing doc links** — Any niri wiki pages you needed that aren't in the Key docs URLs table?
5. **Anything else** — Any other gaps, inaccuracies, or improvements you'd want in this skill?

Based on the user's answers, update this SKILL.md file directly:
- Add new gotchas to the **Common gotchas** section
- Extend the property lists in **window-rule properties** or **layer-rule properties**
- Add missing URLs to the **Key docs URLs** table
- Fix any inaccuracies
- Update the frontmatter `description` if the skill's scope has shifted

Skip the grilling if the session was trivial (e.g. user just asked a question, no config was changed).
