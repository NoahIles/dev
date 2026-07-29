set shell := ["bash", "-euo", "pipefail", "-c"]

# List all recipes
default:
    @just --list

############################################################################
#  Nix
############################################################################

# Update all flake inputs
[group('nix')]
up:
    cd desktop && nix flake update --commit-lock-file

# Update a single flake input
[group('nix')]
upp input:
    cd desktop && nix flake update {{ input }} --commit-lock-file

# List all generations of the system profile
[group('nix')]
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Open a nix repl with this flake loaded
[group('nix')]
repl:
    cd desktop && nix repl .

# Remove all old generations (system + home-manager)
[group('nix')]
clean:
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system
    nix profile wipe-history --profile "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"

# Garbage collect unused store entries (7d retention)
[group('nix')]
gc:
    sudo nix-collect-garbage --delete-older-than 7d
    nix-collect-garbage --delete-older-than 7d

# Format all nix files with alejandra
[group('nix')]
fmt:
    alejandra -q desktop/

# Verify all nix store entries
[group('nix')]
verify-store:
    nix store verify --all

# Repair nix store paths
[group('nix')]
repair-store *paths:
    nix store repair {{ paths }}

############################################################################
#  Build
############################################################################

# Rebuild NixOS (passes args to rebuild.sh)
[group('build')]
rebuild *args:
    cd desktop && ./rebuild.sh {{ args }}

# Build the desktop system without activating it
[group('build')]
build:
    cd desktop && sudo nixos-rebuild build --flake .#desktop

# Build and run the test VM
[group('build')]
vm:
    cd desktop && nixos-rebuild build-vm --flake .#vm
    ./desktop/result/bin/run-*

# Dry-activate to preview what would change
[group('build')]
diff:
    cd desktop && sudo nixos-rebuild dry-activate --flake .#desktop

# Roll back to the previous generation
[group('build')]
rollback:
    sudo nixos-rebuild switch --rollback

############################################################################
#  Services
############################################################################

# List inactive systemd units
[group('services')]
list-inactive:
    systemctl list-units --all --state=inactive

# List failed systemd units
[group('services')]
list-failed:
    systemctl list-units --all --state=failed

# List systemd-* units
[group('services')]
list-systemd:
    systemctl list-units 'systemd-*'

############################################################################
#  Common
############################################################################

# Print $PATH, one entry per line
[group('common')]
path:
    echo "$PATH" | tr ':' '\n'

# Trace file access of a command (excluding /nix/store)
[group('common')]
trace-access app *args:
    strace -f -t -e trace=file {{ app }} {{ args }} 2>&1 | grep -v '/nix/store\|/proc' | grep -oP '"(/[^"]+)"' | sort -u

# Dump environment of a running process
[group('common')]
penvof pid:
    sudo cat /proc/{{ pid }}/environ | tr '\0' '\n'
