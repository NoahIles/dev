{
  config,
  pkgs-unstable,
  ...
}: {
  # from nixos-generate-config 2026-07-13
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage"];
  boot.kernelModules = ["kvm-amd" "nct6687"];
  boot.extraModulePackages = [config.boot.kernelPackages.nct6687d];
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

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
  # ~/.config is its own subvolume — unmanaged app state quarantined from
  # @home; unmount + rebuild = clean-state test of the HM-managed setup.
  # fileSystems."/home/noah/.config" = {
  #   device = "/dev/disk/by-uuid/288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702";
  #   fsType = "btrfs";
  #   options = ["subvol=@config" "noatime" "compress=zstd:3" "discard=async" "commit=120" "nofail"];
  # };
  # # ESP shared with Windows and CachyOS/Limine
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

  # RTX 4080 Super (Ada) — open kernel modules are the supported path.
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.new_feature;
    powerManagement.enable = true;
  };

  # bluetooth (Magic Keyboard) — pairing persists in /var/lib/bluetooth,
  # so the PIN prompt only happens once per pairing. If reconnects ever
  # start stalling on a manual accept again, the device fell back to
  # untrusted — fix: bluetoothctl trust B0:BE:83:E7:DD:7E
  hardware.bluetooth = {
    enable = true;
    package = pkgs-unstable.bluez;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
}
