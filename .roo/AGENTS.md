# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Python-Bash Interface Contract

The Python CLI ([`dev`](dev)) sets `BASE_DIR` as an environment variable before executing bash scripts. Bash scripts MUST use this pattern:

```bash
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
```

This allows scripts to work both when invoked by the Python CLI (which sets `BASE_DIR`) and when run directly. The fallback derives `BASE_DIR` from the script's location.

## Module Idempotency Pattern

Modules in [`quickstart/modules/`](quickstart/modules/) use marker files in `~/.config/dev-setup/modules/` to track completion. The pattern:

1. Check for marker file: `~/.config/dev-setup/modules/<module_name>.done`
2. If exists, exit early with message
3. Perform setup operations
4. Create marker file: `mkdir -p "$STATE_DIR" && touch "$MARKER_FILE"`

This is NOT standard bash practice - it's a custom idempotency mechanism specific to this project. Scripts in [`quickstart/scripts/`](quickstart/scripts/) do NOT use this pattern (they're reusable utilities).

## Script Discovery and Invocation

The Python CLI discovers scripts recursively and supports THREE reference formats:

1. **Basename without extension**: `paru` → resolves to `arch/paru.sh`
2. **Relative path without extension**: `arch/paru` → resolves to `arch/paru.sh`
3. **Full relative path with extension**: `arch/paru.sh`

Basename resolution only works if unique (no conflicts). See [`dev`](dev:87-98) for the lookup logic.

## Privilege Model

Scripts use `sudo` for privileged operations but are NOT run as root. The pattern:

```bash
sudo -v  # Cache credentials at script start
sudo pacman -S ...  # Use sudo for individual commands
```

This is counterintuitive for system setup tools - users run `./dev install` as themselves, not `sudo ./dev install`. The Python CLI never uses sudo; only bash scripts do.

## Fish Shell Command Execution

Bash scripts execute Fish shell commands using `fish -c "command"`. This is the ONLY way to run Fish commands from bash scripts. Examples:

```bash
fish -c "curl -sL https://... | source && fisher install ..."
fish -c "fisher install plugin-name"
```

This pattern appears in modules that configure Fish shell (see [`quickstart/modules/fisher.sh`](quickstart/modules/fisher.sh:21)).

## Module vs Script Distinction

- **Modules** ([`quickstart/modules/`](quickstart/modules/)): One-time setup with idempotency markers
- **Scripts** ([`quickstart/scripts/`](quickstart/scripts/)): Reusable utilities without idempotency

This distinction is NOT obvious from directory structure alone. The key difference is the marker file pattern.

## Path Resolution in Modules

Some modules derive paths using `SCRIPT_DIR` and `PARENT_DIR` instead of `BASE_DIR`:

```bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$(dirname $(dirname "$SCRIPT_DIR"))"
```

This is used when modules need to reference files relative to their own location (see [`quickstart/modules/fish_env.sh`](quickstart/modules/fish_env.sh:5-6)).
