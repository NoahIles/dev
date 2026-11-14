# Shared base for every homelab container: unprivileged Proxmox LXC.
# Create it with `just homelab-create` (unprivileged, nesting=1, keyctl off,
# DHCP); see llm-wiki homelab/nixos-in-lxc.md.
{modulesPath, ...}: {
  imports = ["${modulesPath}/virtualisation/proxmox-lxc.nix"];

  proxmoxLXC.privileged = false;
  # The flake's networking.hostName wins over Proxmox's /etc/hostname. networkd
  # sends it with the DHCP request, so Technitium registers <host>.home.
  proxmoxLXC.manageHostName = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };
  # Copied from desktop/identity.nix, not imported: homelab shares nothing with desktop.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1ZB2LANb2hD3MHbLLmwqbc/8UkV3IPvWgK/Jm4ZhtO Noahiles@gmail.com"
  ];

  # dev#10: hosts converge daily (04:40) to origin's `nixos` branch, so pushing is
  # the deploy. The lock pins nixpkgs: a run with nothing new is a no-op. No
  # fragment needed, nixos-rebuild picks the config by hostname. Failures are
  # mailed by prod1's cron (homelab/prod1/nixos-upgrade-check).
  system.autoUpgrade = {
    enable = true;
    flake = "github:NoahIles/dev/nixos?dir=homelab";
    upgrade = false;
    allowReboot = false;
  };

  networking.nameservers = ["192.168.1.115"];
  time.timeZone = "America/Los_Angeles";
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
