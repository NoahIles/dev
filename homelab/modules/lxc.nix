# Shared base for every homelab container: unprivileged Proxmox LXC.
# Create it with `just homelab-create` (unprivileged, nesting=1, keyctl off,
# DHCP); see llm-wiki homelab/nixos-in-lxc.md.
{modulesPath, ...}: {
  imports = ["${modulesPath}/virtualisation/proxmox-lxc.nix" ./base.nix];

  proxmoxLXC.privileged = false;
  # The flake's networking.hostName wins over Proxmox's /etc/hostname. networkd
  # sends it with the DHCP request, so Technitium registers <host>.home.
  proxmoxLXC.manageHostName = true;
}
