# AGENTS.md - Code Mode

This file provides code-specific guidance for AI assistants working in this repository.

## Environment Variable Propagation

When adding new bash scripts, you MUST include the BASE_DIR fallback pattern:

```bash
[ -z "$BASE_DIR" ] && BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )
```

The number of `..` components depends on script depth:
- Scripts in `quickstart/`: one `..` (see [`quickstart/arch.sh`](../../quickstart/arch.sh:5))
- Scripts in `quickstart/scripts/arch/`: three `..` levels

## Module Creation Requirements

New modules in [`quickstart/modules/`](../../quickstart/modules/) MUST implement the idempotency pattern:

```bash
STATE_DIR="$HOME/.config/dev-setup/modules"
MARKER_FILE="$STATE_DIR/<module_name>.done"

if [ -f "$MARKER_FILE" ]; then
    echo "<module_name> module already completed, skipping..."
    exit 0
fi

# ... setup logic ...

mkdir -p "$STATE_DIR"
touch "$MARKER_FILE"
```

Scripts in [`quickstart/scripts/`](../../quickstart/scripts/) should NOT use this pattern.

## Fish Shell Integration Pattern

When writing bash scripts that configure Fish shell, use `fish -c "command"` syntax:

```bash
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
```

Do NOT attempt to source Fish scripts directly in bash or use heredocs with Fish syntax.

## Script Naming and Discovery

The Python CLI strips extensions during lookup. When creating new scripts:

1. Use `.sh` or `.bash` extensions consistently
2. Ensure basename is unique across all platform directories to enable shorthand invocation
3. Scripts are auto-discovered - no registration needed

## Privilege Escalation Pattern

New scripts requiring root access MUST:

1. Cache credentials at start: `sudo -v`
2. Use `sudo` for individual privileged commands
3. NOT require the entire script to run as root

Example from [`quickstart/scripts/arch/paru.sh`](../../quickstart/scripts/arch/paru.sh:7-9):

```bash
sudo -v
sudo pacman -S --needed --noconfirm base-devel rustup
```

## Path Resolution for File Operations

When modules need to copy files from the repository:

- Use `PARENT_DIR` derivation if the module needs to reference `env/` or other top-level directories
- See [`quickstart/modules/fish_env.sh`](../../quickstart/modules/fish_env.sh:5-6) for the pattern

This is necessary because modules don't have direct access to `BASE_DIR` when deriving relative paths to sibling directories.
