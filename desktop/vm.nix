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

  # The shared seed (home.nix noctaliaSeed) points wallpapers at ~/Pictures,
  # which the VM doesn't have: pre-empt it with a copy whose wallpaper paths
  # are swapped for a store image so the VM isn't a black screen. noctaliaSeed
  # then sees the file and skips; noctalia keeps writing to it after that.
  home-manager.users.${identity.username} = {lib, ...}: let
    wpDir = "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray}/share/backgrounds/nixos";
    vmSeed = pkgs.runCommand "noctalia-vm-seed.toml" {} ''
      sed -e 's|"[^"]*_Wallpapers/[^"]*"|"${wpDir}/nix-wallpaper-nineish-dark-gray.png"|g' \
          -e 's|"[^"]*_Wallpapers"|"${wpDir}"|g' \
          ${./configs/noctalia-seed/settings.toml} > $out
    '';
  in {
    home.activation.noctaliaVmSeed = lib.hm.dag.entryBetween ["noctaliaSeed"] ["writeBoundary"] ''
      d="$HOME/.local/state/noctalia"
      if [ ! -e "$d/settings.toml" ] && [ ! -L "$d/settings.toml" ]; then
        run install -Dm644 ${vmSeed} "$d/settings.toml"
        run touch "$d/.setup-complete"
      fi
    '';
  };

  # bare-metal modules set these — disable in VM
  hardware.nvidia.modesetting.enable = lib.mkForce false;
  services.xserver.videoDrivers = lib.mkForce [];
  hardware.bluetooth.enable = lib.mkForce false;
}
