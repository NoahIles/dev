{
  pkgs,
  inputs,
  ...
}: let
  # television 0.15.7+ is needed for the multi-command [source] channel schema
  # used by ~/.config/television/cable/*.toml; stable (26.05) still ships 0.15.6.
  pkgs-unstable = import inputs.nixpkgs-unstable {inherit (pkgs) system;};
in {
  # from nixos-generate-config 2026-07-13
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage"];
  boot.kernelModules = ["kvm-amd"];
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # Shared btrfs on nvme0n1p1 (same fs as CachyOS). NixOS lives in its own
  # @nixos subvolume; @home is SHARED with CachyOS. Create at install time:
  #   mount /dev/nvme0n1p1 /mnt && btrfs subvolume create /mnt/@nixos
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702";
    fsType = "btrfs";
    options = ["subvol=@nixos" "noatime" "compress=zstd:3" "discard=async" "commit=120"];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702";
    fsType = "btrfs";
    options = ["subvol=@home" "noatime" "compress=zstd:3" "discard=async" "commit=120"];
  };
  # ESP shared with Windows and CachyOS/Limine
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9FE9-13C0";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
  fileSystems."/mnt/linux_games" = {
    device = "/dev/disk/by-uuid/aeb686ed-b3c4-4df3-832b-535be4780d48";
    fsType = "btrfs";
    options = ["noatime" "compress=zstd:3"];
  };

  # NixOS installs NO bootloader: CachyOS's Limine owns booting.
  # limine-sync.sh copies+signs the kernel to the ESP and maintains the
  # /+NixOS entry in /boot/limine.conf. (grub is the NixOS default — must
  # be explicitly disabled.)
  boot.loader.grub.enable = false;

  zramSwap.enable = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Los_Angeles";

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true; # nvidia, steam, zed extensions etc.

  # ponytail: initialPassword only applies if the user is created fresh;
  # set a real one with `passwd` on first boot.
  users.users.noah = {
    isNormalUser = true;
    uid = 1000; # must match CachyOS uid for shared @home
    extraGroups = ["wheel" "networkmanager" "video"];
    shell = pkgs.fish;
    initialPassword = "noah";
  };
  programs.fish.enable = true;

  # RTX 4080 Super (Ada) — open kernel modules are the supported path.
  # ponytail: still merge nixos-generate-config output at install time
  # (initrd modules, microcode) — this file only covers what's known now.
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };

  # power profile switching (Noctalia's power-profiles widget needs this)
  services.power-profiles-daemon.enable = true;

  # niri session, autologin straight into it
  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "niri-session";
      user = "noah";
    };
  };

  programs.steam = {
    enable = true;
    # extest XTEST shim so the Steam Controller works / cursor isn't invisible on wayland
    # `extest.enable` only preloads the 32-bit libextest.so.
    extest.enable = false;
    package = pkgs.steam.override {
      extraEnv.LD_PRELOAD = "${pkgs.pkgsi686Linux.extest}/lib/libextest.so:${pkgs.extest}/lib/libextest.so";
    };
  };

  programs.gamemode = {
    enable = true;
    # Optional: customize settings like soft real-time and renice
    enableRenice = true;
    settings = {
      general = {
        softrealtime = "auto";
        renice = 10;
      };
    };
  };

  # shared @home has AppImages (~/.local/bin) and CachyOS-built binaries
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.nix-ld.enable = true;

  # bluetooth (Magic Keyboard) — pairing persists in /var/lib/bluetooth,
  # so the PIN prompt only happens once per pairing
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # swaylock needs a PAM entry to actually unlock
  security.pam.services.swaylock = {};

  # pkexec needs the setuid wrapper (polkit.enable) and an auth agent
  # to show the password prompt (soteria works on any Wayland compositor)
  security.polkit.enable = true;
  # security.polkit.enablePkexecWrapper = true; # opt-in since nixpkgs 26.05
  security.soteria.enable = true;

  # niri keybind Mod+E spawns "$FILE_MANAGER"
  environment.sessionVariables.FILE_MANAGER = "nautilus";
  # niri keybind Mod+Return spawns "$TERMINAL"
  environment.sessionVariables.TERMINAL = "alacritty";

  environment.systemPackages = with pkgs; [
    sbctl # limine-sync.sh signs the ESP kernel (keys under /var/lib/sbctl)
    alejandra # rebuild.sh formats *.nix
    eza # Ls replacement
    starship # Terminal Prompt
    zoxide # cd replacement
    bat # cat replacement
    duf # du for filesystems
    dust # du repalcement
    trashy # rm replacement
    pkgs-unstable.television # fuzzy finder (unstable: 0.15.9, supports multi-command source schema)
    jq # filter json
    fd # Better find
    ripgrep # Ripgrep
  ];

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.hack # Currently used by alacrity
    nerd-fonts.jetbrains-mono
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro # Default System font
  ];

  # Pin defaults so the generic aliases don't drift when the font set /
  # cache is rebuilt (this is why the font changed after a reboot).
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["SF Pro Display" "SF Pro Text" "Inter"];
    monospace = ["JetBrainsMono Nerd Font"];
  };

  system.stateVersion = "25.05";
}
