#!/usr/bin/env bash
# Build and run the VM using the HOST qemu — the nix-built qemu can't load
# host GL drivers on non-NixOS (/run/opengl-driver missing), and niri needs
# virgl, so host qemu it is.
set -euo pipefail
cd "$(dirname "$0")"
nix build .#nixosConfigurations.vm.config.system.build.vm
sed 's|exec [^ ]*/bin/qemu-system-x86_64|exec /usr/bin/qemu-system-x86_64|' \
  result/bin/run-nixos-vm-vm > /tmp/run-nixos-vm-hostqemu
chmod +x /tmp/run-nixos-vm-hostqemu
exec /tmp/run-nixos-vm-hostqemu "$@"
