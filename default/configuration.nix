{ pkgs, ... }:

{
  # ponytail: VM stubs — replace with nixos-generate-config output on bare metal
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.noah = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.fish;
    initialPassword = "noah";
  };
  programs.fish.enable = true;

  # niri session, autologin straight into it
  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "niri-session";
      user = "noah";
    };
  };

  # audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # swaylock needs a PAM entry to actually unlock
  security.pam.services.swaylock = { };

  # niri keybind Mod+E spawns "$FILE_MANAGER"
  environment.sessionVariables.FILE_MANAGER = "nautilus";

  fonts.packages = with pkgs; [
    inter
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  # VM settings for `nixos-rebuild build-vm`
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  };

  system.stateVersion = "25.05";
}
