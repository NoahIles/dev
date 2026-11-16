set shell := ["bash", "-euo", "pipefail", "-c"]

# List all recipes
default:
    @just --list

############################################################################
#  Nix
############################################################################

# Refresh the noctalia settings seed, then update all flake inputs
[group('nix')]
up: noctalia-seed
    cd desktop && nix flake update --commit-lock-file

# Snapshot live noctalia settings into the seed (drops private tables: location, battery serials)
[group('nix')]
noctalia-seed:
    #!/usr/bin/env bash
    set -euo pipefail
    live="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml"
    seed=desktop/configs/noctalia-seed/settings.toml
    [ -f "$live" ] || exit 0
    awk '/^[[:space:]]*\[/{skip = /^[[:space:]]*\[(location|battery\.device\.)/} !skip' "$live" > "$seed"
    git diff --quiet -- "$seed" || git commit -q -m "chore(noctalia): refresh settings seed" -- "$seed"

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

# Rebuild NixOS (passes args to rebuild.sh, quoting intact)
[group('build')]
[positional-arguments]
rebuild *args:
    cd desktop && ./rebuild.sh "$@"

# Check formatting and evaluate the desktop config (the bar every commit must pass)
[group('build')]
check:
    alejandra -q --check desktop/ homelab/
    nix build --no-link --dry-run ./desktop#nixosConfigurations.NixIsland.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.apt-cacher-ng.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.prowlarr.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.radarr.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.sonarr.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.qbittorrent.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.headscale.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.docker-test.config.system.build.toplevel
    nix build --no-link --dry-run ./homelab#nixosConfigurations.docker-test.config.system.build.images.proxmox

# Build the desktop system without activating it
[group('build')]
build:
    cd desktop && nixos-rebuild build --flake .#NixIsland

# Build and run the test VM on a fresh disk (every boot is a first boot)
[group('build')]
vm:
    cd desktop && nixos-rebuild build-vm --flake .#vm
    rm -f nixos-vm.qcow2
    ./desktop/result/bin/run-*

# Dry-activate to preview what would change
[group('build')]
diff:
    cd desktop && sudo nixos-rebuild dry-activate --flake .#NixIsland

# Roll back to the previous generation
[group('build')]
rollback:
    sudo nixos-rebuild switch --rollback

############################################################################
#  Homelab
############################################################################

# Build a homelab host's Proxmox LXC tarball (same output as images.proxmox-lxc)
[group('homelab')]
homelab-image host:
    nix build ./homelab#nixosConfigurations.{{ host }}.config.system.build.tarball -o result-{{ host }}

# ponytail: stands in for Terraform (dev#6) as the one Proxmox-side spec until then.
# Create a homelab host's container on prod1: upload image, create, start, pin key
[group('homelab')]
homelab-create host vmid memory="512" disk="10" mp="": (homelab-image host)
    scp result-{{ host }}/tarball/*.tar.xz root@prox:/var/lib/vz/template/cache/nixos-{{ host }}.tar.xz
    ssh root@prox pct create {{ vmid }} local:vztmpl/nixos-{{ host }}.tar.xz --hostname {{ host }} --ostype nixos --unprivileged 1 --features nesting=1 --cmode console --cores 1 --memory {{ memory }} --rootfs local-lvm:{{ disk }} {{ if mp != "" { "--mp0 " + mp + " " } else { "" } }}--net0 name=eth0,bridge=vmbr0,ip=dhcp,ip6=auto --onboot 1
    ssh root@prox pct start {{ vmid }}
    just homelab-pin-key {{ host }} {{ vmid }}

# Build a homelab VM host's Proxmox image (vma.zst, restored with qmrestore)
[group('homelab')]
homelab-image-vm host:
    nix build ./homelab#nixosConfigurations.{{ host }}.config.system.build.images.proxmox -o result-{{ host }}

# Create and start a homelab VM on prod1 from its image (onboot 0); then run
# `just homelab-pin-key-vm`.
[group('homelab')]
homelab-create-vm host vmid: (homelab-image-vm host)
    scp result-{{ host }}/*.vma.zst root@prox:/var/lib/vz/dump/vzdump-qemu-{{ vmid }}-nixos-{{ host }}.vma.zst
    ssh root@prox qmrestore /var/lib/vz/dump/vzdump-qemu-{{ vmid }}-nixos-{{ host }}.vma.zst {{ vmid }} --storage local-lvm --unique 1
    ssh root@prox qm set {{ vmid }} --name {{ host }} --onboot 0 --boot order=virtio0 --delete ide2
    ssh root@prox qm start {{ vmid }}

# Trust a VM's SSH host key as <host>.home, read through the guest agent
[group('homelab')]
homelab-pin-key-vm host vmid:
    ssh root@prox 'timeout 180 sh -c "until qm guest exec {{ vmid }} -- /run/current-system/sw/bin/test -s /etc/ssh/ssh_host_ed25519_key.pub >/dev/null 2>&1; do sleep 2; done"'
    -ssh-keygen -R {{ host }}.home
    echo "{{ host }}.home $(ssh root@prox qm guest exec {{ vmid }} -- /run/current-system/sw/bin/cat /etc/ssh/ssh_host_ed25519_key.pub | jq -r '."out-data"' | cut -d' ' -f1,2)" >> ~/.ssh/known_hosts

# Read through prod1 rather than accepted blind on first connect; re-run after
# recreating a container.
# Trust a container's SSH host key as <host>.home
[group('homelab')]
homelab-pin-key host vmid:
    ssh root@prox 'timeout 60 sh -c "until pct exec {{ vmid }} -- /run/current-system/sw/bin/test -s /etc/ssh/ssh_host_ed25519_key.pub; do sleep 1; done"'
    -ssh-keygen -R {{ host }}.home
    echo "{{ host }}.home $(ssh root@prox pct exec {{ vmid }} -- /run/current-system/sw/bin/cat /etc/ssh/ssh_host_ed25519_key.pub | cut -d' ' -f1,2)" >> ~/.ssh/known_hosts

# Build a homelab host locally and switch the running container to it over SSH
[group('homelab')]
deploy host target=(host + ".home"):
    nixos-rebuild switch --flake ./homelab#{{ host }} --target-host root@{{ target }}

# Deploy every homelab host from this checkout; carries on past a failed host
[group('homelab')]
deploy-all:
    #!/usr/bin/env bash
    rc=0
    for h in $(nix eval --raw ./homelab#nixosConfigurations --apply 'c: toString (builtins.attrNames c)'); do
      echo "== $h"
      just deploy "$h" || { echo "!! $h failed"; rc=1; }
    done
    exit $rc

# Per host: does it run what this checkout builds? (catches a forgotten deploy)
[group('homelab')]
homelab-status:
    #!/usr/bin/env bash
    for h in $(nix eval --raw ./homelab#nixosConfigurations --apply 'c: toString (builtins.attrNames c)'); do
      want=$(nix eval --raw ./homelab#nixosConfigurations.$h.config.system.build.toplevel.outPath)
      have=$(ssh root@$h.home readlink /run/current-system)
      [ "$have" = "$want" ] && s=in-sync || s="DRIFT: just deploy $h"
      printf '%-20s %s\n' "$h" "$s"
    done

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
