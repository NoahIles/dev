# Shared by every homelab guest, LXC or VM: ssh, key, DNS, time, nix settings.
{
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };
  # Copied from desktop/identity.nix, not imported: homelab shares nothing with desktop.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1ZB2LANb2hD3MHbLLmwqbc/8UkV3IPvWgK/Jm4ZhtO Noahiles@gmail.com"
  ];

  # ponytail: no autoUpgrade. dev#10: hosts are deployed from the desktop
  # (`just deploy-all`); the lock pins nixpkgs, so a host only changes when we do.

  networking.nameservers = ["192.168.1.115"];
  time.timeZone = "America/Los_Angeles";
  nix.settings.experimental-features = ["nix-command" "flakes"];
}
