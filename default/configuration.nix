{ pkgs, ... }:

{
  # Shared btrfs on nvme0n1p1 (same fs as CachyOS). NixOS lives in its own
  # @nixos subvolume; @home is SHARED with CachyOS. Create at install time:
  #   mount /dev/nvme0n1p1 /mnt && btrfs subvolume create /mnt/@nixos
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702";
    fsType = "btrfs";
    options = [ "subvol=@nixos" "noatime" "compress=zstd:3" "discard=async" "commit=120" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702";
    fsType = "btrfs";
    options = [ "subvol=@home" "noatime" "compress=zstd:3" "discard=async" "commit=120" ];
  };
  # ESP shared with Windows and CachyOS/Limine
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9FE9-13C0";
    fsType = "vfat";
  };
  fileSystems."/mnt/linux_games" = {
    device = "/dev/disk/by-uuid/aeb686ed-b3c4-4df3-832b-535be4780d48";
    fsType = "btrfs";
    options = [ "noatime" "compress=zstd:3" ];
  };

  # ponytail: systemd-boot alongside Limine on the shared ESP for now.
  # Secure Boot signing (user keys) is a separate migration step — until
  # then, boot NixOS with SB disabled or via a signed Limine entry.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap.enable = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true; # nvidia, steam, zed extensions etc.

  # ponytail: initialPassword only applies if the user is created fresh;
  # set a real one with `passwd` on first boot.
  users.users.noah = {
    isNormalUser = true;
    uid = 1000; # must match CachyOS uid for shared @home
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.fish;
    initialPassword = "noah";
  };
  programs.fish.enable = true;

  # RTX 4080 Super (Ada) — open kernel modules are the supported path.
  # ponytail: still merge nixos-generate-config output at install time
  # (initrd modules, microcode) — this file only covers what's known now.
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };

  # niri session, autologin straight into it
  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "niri-session";
      user = "noah";
    };
  };

  programs.steam.enable = true;

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

  system.stateVersion = "25.05";
}
