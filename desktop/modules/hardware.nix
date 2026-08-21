{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  # Seeded by nixos-generate-config 2026-07-13, hand-maintained since.
  # Deliberately NOT named hardware-configuration.nix: the generator
  # overwrites that filename unconditionally (--force only guards
  # configuration.nix). To refresh from a new machine, generate into a
  # scratch dir and merge by hand.
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage"];
  boot.kernelModules = ["kvm-amd" "nct6687"];
  # ponytail: kernel 7.2 removed strncpy; upstream nct6687d still uses it.
  # strscpy is the drop-in replacement (it NUL-terminates). Drop when upstream
  # (or nixpkgs) fixes it.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.nct6687d.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace nct6687.c \
            --replace-fail "strncpy(valcp, val, 16);" "strscpy(valcp, val, 16);"
        '';
    }))
  ];
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
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    powerManagement.enable = true;
  };

  # RodeCaster virtual sinks (Game/Music/A/B) and the per-app routing that
  # targets them. System-level because they describe this box's audio
  # interface — the VM has no RodeCaster and shouldn't build them.
  # configPackages, not environment.etc: NixOS asserts against writing to
  # /etc/pipewire directly.
  services.pipewire.configPackages = [
    (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/99-rodecaster-virtual-sinks.conf"
      (builtins.readFile ../configs/pipewire/99-rodecaster-virtual-sinks.conf))
    (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/90-app-routing.conf"
      (builtins.readFile ../configs/pipewire/90-app-routing.conf))
  ];

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
