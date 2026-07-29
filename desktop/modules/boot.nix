{pkgs-unstable, ...}: {
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  boot.loader.limine = {
    enable = true;
    maxGenerations = 10;
    secureBoot.enable = true;

    extraConfig = ''
      remember_last_entry: no
    '';

    extraEntries = ''
      /+CachyOS
        //linux-cachyos
          protocol: linux
          path: boot():/50c7e670d55a41ec9fadc18423e4845a/linux-cachyos/vmlinuz-linux-cachyos
          module_path: boot():/50c7e670d55a41ec9fadc18423e4845a/linux-cachyos/initramfs-linux-cachyos
          cmdline: nowatchdog rw rootflags=subvol=/@ root=UUID=288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702
        //linux-cachyos-lts
          protocol: linux
          path: boot():/50c7e670d55a41ec9fadc18423e4845a/linux-cachyos-lts/vmlinuz-linux-cachyos-lts
          module_path: boot():/50c7e670d55a41ec9fadc18423e4845a/linux-cachyos-lts/initramfs-linux-cachyos-lts
          cmdline: nowatchdog rw rootflags=subvol=/@ root=UUID=288a2b9a-42f1-49b8-9fa5-fb4dcb9f9702

      /Windows Boot Manager
        protocol: efi_chainload
        image_path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };

  # hid-logitech-dj in latest kernel has the Superstrike's Lightspeed receiver id
  boot.kernelPackages = pkgs-unstable.linuxPackages_latest;

  zramSwap.enable = true;
}
