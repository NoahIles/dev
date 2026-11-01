{
  lib,
  pkgs,
  identity,
  inputs,
  ...
}: {
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

  # QEMU's screendump has no surface under virtio-vga-gl, so screenshots come
  # from inside the guest (nixos-vm-test skill's `vm.sh shot`).
  environment.systemPackages = [pkgs.grim];

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

  home-manager.users.${identity.username} = {lib, ...}: {
    # Stands in for the manual `git clone` on a new machine, so live-lane
    # dotfiles link into ~/nixos exactly as on the host. Tracked files only.
    # ponytail: no .git — add one if the VM ever needs to run rebuild.sh.
    home.activation.seedRepoCheckout = lib.hm.dag.entryBefore ["writeBoundary"] ''
      if [ ! -e "$HOME/nixos" ]; then
        run cp -rT --no-preserve=mode ${inputs.self.sourceInfo.outPath} "$HOME/nixos"
        # Flush now: closing the QEMU window right after first boot otherwise
        # leaves ext4 with 0-byte files, which this check never replaces.
        run sync
      fi
    '';
  };

  # bare-metal modules set these — disable in VM
  hardware.nvidia.modesetting.enable = lib.mkForce false;
  services.xserver.videoDrivers = lib.mkForce [];
  hardware.bluetooth.enable = lib.mkForce false;
}
