# Dev Setup

A cross-platform development environment setup tool that automates system configuration through a modular, idempotent Python CLI.

## Features

- **Cross-Platform Support**: Arch Linux, Debian/Ubuntu, and macOS
- **Idempotent Operations**: Safe to run multiple times without side effects
- **Modular Architecture**: Separate one-time setup tasks from reusable utilities
- **Recursive Script Discovery**: Automatically finds and organizes platform-specific scripts
- **Comprehensive Error Handling**: Clear error messages and graceful failure recovery
- **Consistent Privilege Model**: Uses sudo only when necessary, with credential caching
- **Flexible Execution**: Run full installation or individual modules/scripts

## Requirements

- **Bash** shell (for the `start` wrapper)
- **curl** (for mise installation)
- **Platform-specific tools**:
  - Debian/Ubuntu: `apt`

All other dependencies (Python 3.10, uv, ruff, brew) are automatically managed by [mise](https://mise.jdx.dev/).

## Quick Start

### Automated Setup (Recommended)

Use the `start` wrapper to automatically handle mise installation and tool setup:

```bash
git clone <repository-url>
cd dev
./start install
```

The `start` script will:
1. Install mise if not already present
2. Install Python 3.10, uv, and ruff via mise
3. Create a Python virtual environment
4. Install Python dependencies
5. Run the platform-specific installation

### Manual Setup

If you prefer to manage mise yourself or already have it installed:

1. Clone the repository:
```bash
git clone <repository-url>
cd dev
```

2. Install mise (if not already installed):
```bash
curl https://mise.run/install.sh | sh
```

3. Install tools and dependencies:
```bash
mise install
```

4. Run the setup:
```bash
./dev install
```

## Usage

### Full Installation

Run the complete setup for your platform, including all modules:

```bash
./start install  # Recommended: handles mise automatically
# OR
./dev install    # If you've already set up mise
```

This command:
1. Detects your operating system
2. Runs the appropriate platform-specific installation script
3. Executes all modules in the `quickstart/modules/` directory

### List Available Modules and Scripts

View all available modules and scripts organized by platform:

```bash
./start list
# OR
./dev list
```

Example output:
```
Modules:
  fish_env
  fisher

Scripts:
  [arch]
    paru (arch/paru.sh)
    shell (arch/shell.bash)
    podman (arch/podman.bash)
    greetd (arch/greetd.bash)
    nvim (arch/nvim.bash)
    waybar (arch/waybar.bash)
  [deb]
    vim (deb/vim.bash)
```

### Run Specific Modules or Scripts

Execute one or more modules or scripts by name:

```bash
./start run <name> [<name2> ...]
# OR
./dev run <name> [<name2> ...]
```

Examples:
```bash
# Run a single module
./start run fisher

# Run a platform-specific script (multiple ways)
./start run paru                    # By basename
./start run arch/paru              # By relative path
./start run arch/paru.sh           # With extension

# Run multiple items at once
./start run fisher paru shell
```

## Architecture

The project uses a two-tier system to organize setup tasks:

### Modules (`quickstart/modules/`)

**One-time setup tasks** that should only run once. Modules use marker files to track completion state:

- Located in `quickstart/modules/`
- Implement idempotency checks using marker files in `~/.config/dev-setup/modules/`
- Example: `fisher.sh` installs the Fisher plugin manager for Fish shell

### Scripts (`quickstart/scripts/`)

**Reusable utilities** organized by platform that can be run multiple times:

- Located in `quickstart/scripts/<platform>/`
- Platform-specific: `arch/`, `deb/`, etc.
- Can be invoked by basename, relative path, or full path
- Example: `arch/paru.sh` installs the Paru AUR helper

### Platform Scripts (`quickstart/`)

Platform-specific installation entry points:

- `install.sh` - Detects OS and delegates to platform script
- `arch.sh` - Arch Linux setup
- `deb.sh` - Debian/Ubuntu setup
- `osx.sh` - macOS setup
- `shared.sh` - Common utilities

## Supported Platforms

| Platform | Status | Package Manager |
|----------|--------|-----------------|
| Arch Linux | ✅ Supported | pacman, paru (AUR) |
| Debian/Ubuntu | ✅ Supported | apt |
| macOS | ✅ Supported | Homebrew |
| Fedora/RHEL | ❌ Not yet supported | - |
| Windows | ❌ Not yet supported see `docs/branches.md` | - |

## Project Structure

```
.
├── dev                          # Main Python CLI tool
├── requirements.txt             # Python dependencies (Click)
├── LICENSE                      # MIT License
├── quickstart/
│   ├── install.sh              # OS detection and delegation
│   ├── arch.sh                 # Arch Linux installation
│   ├── deb.sh                  # Debian/Ubuntu installation
│   ├── osx.sh                  # macOS installation
│   ├── shared.sh               # Shared utilities
│   ├── modules/                # One-time setup modules
│   │   ├── fisher.sh           # Fisher plugin manager
│   │   └── fish_env.sh         # Fish shell environment
│   ├── scripts/                # Reusable platform scripts
│   │   ├── arch/               # Arch Linux scripts
│   │   │   ├── paru.sh         # AUR helper installation
│   │   │   ├── shell.bash      # Shell configuration
│   │   │   ├── podman.bash     # Container runtime
│   │   │   ├── greetd.bash     # Display manager
│   │   │   ├── nvim.bash       # Neovim setup
│   │   │   └── waybar.bash     # Wayland bar
│   │   └── deb/                # Debian/Ubuntu scripts
│   │       └── vim.bash        # Vim setup
│   └── apps/                   # Application lists
│       ├── PersonalBrewfile    # Personal macOS apps
│       └── workBrew            # Work macOS apps
└── docs/
    ├── branches.md             # Historical branch information
    └── todo.md                 # Development tasks
```

## Development

### Adding a New Module

1. Create a new script in `quickstart/modules/`:
```bash
touch quickstart/modules/my_module.sh
chmod +x quickstart/modules/my_module.sh
```

2. Implement idempotency using marker files:
```bash
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="$HOME/.config/dev-setup/modules"
MARKER_FILE="$STATE_DIR/my_module.done"

if [ -f "$MARKER_FILE" ]; then
    echo "my_module already completed, skipping..."
    exit 0
fi

# Your setup logic here

mkdir -p "$STATE_DIR"
touch "$MARKER_FILE"
echo "my_module completed successfully."
```

### Adding a New Script

1. Create a script in the appropriate platform directory:
```bash
touch quickstart/scripts/arch/my_script.sh
chmod +x quickstart/scripts/arch/my_script.sh
```

2. The script will be automatically discovered and available via `./dev run`

### Extending Platform Support

To add support for a new platform:

1. Create a platform script in `quickstart/` (e.g., `fedora.sh`)
2. Add detection logic to `quickstart/install.sh`
3. Create a platform-specific scripts directory: `quickstart/scripts/fedora/`
4. Add platform-specific installation logic

## Recent Improvements

- **Idempotent Modules**: Modules now use marker files to prevent duplicate execution
- **Recursive Script Discovery**: Scripts are automatically discovered in subdirectories
- **Flexible Script Invocation**: Scripts can be called by basename, relative path, or full path
- **Comprehensive Error Handling**: Better error messages and graceful failure recovery
- **Consistent Privilege Model**: Standardized sudo usage with credential caching
- **Environment Variable Support**: `BASE_DIR` is passed from Python CLI to shell scripts

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contributing

Contributions are welcome! Please ensure:

- Scripts follow the established privilege model (sudo only when necessary)
- Modules implement idempotency checks
- Error handling is comprehensive with clear messages
- Code follows existing patterns and conventions

---

For historical information about the repository's previous branch-based organization, see `docs/branches.md`.
