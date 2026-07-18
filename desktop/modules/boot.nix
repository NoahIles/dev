{pkgs, ...}: {
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
}
