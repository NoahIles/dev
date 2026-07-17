{
  pkgs,
  inputs,
  ...
}: let
  # television 0.15.7+ is needed for the multi-command [source] channel schema
  # used by ~/.config/television/cable/*.toml; stable (26.05) still ships 0.15.6.
  pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";};
in {
  # NixOS installs NO bootloader: CachyOS's Limine owns booting.
  # limine-sync.sh copies+signs the kernel to the ESP and maintains the
  # /+NixOS entry in /boot/limine.conf. (grub is the NixOS default — must
  # be explicitly disabled.)
  boot.loader.grub.enable = false;

  # 6.18 LTS's hid-logitech-dj lacks the Superstrike's Lightspeed receiver id
  # (046d:c54d), so no hidpp_battery appears for UPower/Noctalia. Latest kernel
  # has it. Kernel bump => rebuild.sh will re-sign/sync the ESP via limine-sync.
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # power profile switching (Noctalia's power-profiles widget needs this)
  services.power-profiles-daemon.enable = true;

  # battery widget (Noctalia reads battery/peripheral levels via UPower over DBus)
  services.upower.enable = true;

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

  environment.sessionVariables.STEAM_EDITOR = "zeditor";
  # nautilus smb:// (and trash/mtp) needs gvfs
  services.gvfs.enable = true;
  # right-click "Open in Terminal" in nautilus
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };
  # niri keybind Mod+Return spawns "$TERMINAL"
  environment.sessionVariables.TERMINAL = "alacritty";
  # dconf gtk-theme is cachyos-nord (shared home, not installed here), so GTK3
  # apps (solaar etc.) fell back to light Adwaita. Force dark NixOS-side only.
  environment.sessionVariables.GTK_THEME = "Adwaita:dark";

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
    fd # Better find
    fzf # Fuzzy Finder
    pkgs-unstable.television # fuzzy finder (unstable: 0.15.9, supports multi-command source schema)
    ripgrep # Ripgrep
    jq # filter json

    vim # better nano
    helix # better vim?
  ];

  fonts.packages = with pkgs; [
    inter
    nerd-fonts.hack # Currently used by alacrity
    nerd-fonts.jetbrains-mono
    inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro # Default System font
  ];

  # Pin defaults so the generic aliases don't drift when the font set /
  # cache is rebuilt (this is why the font changed after a reboot).
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["SF Pro Display" "SF Pro Text" "Inter"];
    monospace = ["JetBrainsMono Nerd Font"];
  };

  system.stateVersion = "25.05";
}
