{lib, ...}: {
  home-manager.extraSpecialArgs._isVM = lib.mkForce true;

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
        guest.port = 22;
      }
    ];
    qemu.options = [
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  };

  # bare-metal modules set these — disable in VM
  hardware.nvidia.modesetting.enable = lib.mkForce false;
  services.xserver.videoDrivers = lib.mkForce [];
  hardware.bluetooth.enable = lib.mkForce false;
}
