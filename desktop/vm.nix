{
  lib,
  pkgs,
  identity,
  ...
}: {
  # NixIsland sets false in flake.nix; mkForce can't win inside an attrs option.
  home-manager.extraSpecialArgs._isVM = true;

  # ponytail: VM-only overrides — everything else comes from shared modules
  boot.loader.systemd-boot.enable = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = lib.mkForce "nixos-vm";

  # niri needs a hw renderer — virgl via virtio-vga-gl
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
    forwardPorts = [
      {
        from = "host";
        host.port = 2223;
        guest.port = 2222; # modules/ssh.nix
      }
    ];
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on,grab-on-hover=on" # keyboard only (Super to the guest), mouse stays free
    ];
  };

  # QEMU draws virtio-gpu's hardware cursor ~48px below the real pointer.
  # Make wlroots compositors (umbriel, the greeter) draw it into the frame.
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # Resizing the QEMU window changes the guest monitor's preferred mode, but
  # umbriel never re-reads its mode list. Apply the new size on each DRM event.
  systemd.user.services.vm-autoresize = {
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    path = [pkgs.systemd pkgs.wlr-randr];
    script = ''
      udevadm monitor --udev --subsystem-match=drm | while read -r _; do
        mode=$(head -1 /sys/class/drm/card*-Virtual-1/modes)
        wlr-randr --output Virtual-1 --custom-mode "$mode" || true
      done
    '';
  };

  # Real noctalia settings live in ~/.local/state/noctalia (runtime state,
  # not in the repo). Seed a wallpaper once so the VM isn't a black screen;
  # noctalia keeps writing to the file after that.
  home-manager.users.${identity.username} = {lib, ...}: {
    home.activation.noctaliaVmSeed = lib.hm.dag.entryAfter ["writeBoundary"] ''
      d="$HOME/.local/state/noctalia"
      if [ ! -e "$d/settings.toml" ]; then
        mkdir -p "$d"
        touch "$d/.setup-complete"
        printf '[wallpaper.default]\npath = "%s"\n' \
          "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos/nix-wallpaper-nineish-dark-gray.png" \
          > "$d/settings.toml"
      fi
    '';
  };

  # bare-metal modules set these — disable in VM
  hardware.nvidia.modesetting.enable = lib.mkForce false;
  services.xserver.videoDrivers = lib.mkForce [];
  hardware.bluetooth.enable = lib.mkForce false;
}
