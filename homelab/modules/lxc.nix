# Shared base for every homelab container: unprivileged Proxmox LXC.
# Container must be created with --unprivileged 1 and nesting=1, keyctl off
# (see llm-wiki homelab/nixos-in-lxc.md).
{modulesPath, ...}: {
  imports = ["${modulesPath}/virtualisation/proxmox-lxc.nix"];

  proxmoxLXC.privileged = false;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };
  # Copied from desktop/identity.nix, not imported: homelab shares nothing with desktop.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1ZB2LANb2hD3MHbLLmwqbc/8UkV3IPvWgK/Jm4ZhtO Noahiles@gmail.com"
  ];

  networking.nameservers = ["192.168.1.115"];
  time.timeZone = "America/Los_Angeles";
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
