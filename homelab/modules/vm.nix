# Shared base for every homelab VM: QEMU guest on Proxmox. Do not import
# proxmox-image.nix here: `system.build.images.proxmox` adds it itself (via
# image.modules), so the same config also deploys with nixos-rebuild.
# Create one with `just homelab-create-vm`.
{
  imports = [./base.nix];

  # DHCP on whatever the NIC is called; the hostname goes out with the request
  # so Technitium registers <host>.home. qemu-guest-agent comes from the image.
  networking.useDHCP = true;
  services.qemuGuest.enable = true;

  # Mirrors proxmox-image.nix's legacy-BIOS layout so `nixos-rebuild switch`
  # on the running VM builds a bootable generation. Without it the plain host
  # config does not even evaluate (no root fs). Identical values merge cleanly
  # with the image's own definitions.
  boot.loader.grub.device = "/dev/vda";
  boot.growPartition = true;
  boot.kernelParams = ["console=ttyS0"];
  boot.initrd.availableKernelModules = ["uas" "virtio_blk" "virtio_pci"];
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  image.modules.proxmox = {
    # The image defaults to a cloud-init drive that blanks hostName and DHCP.
    # Static flake config is the source of truth here, as for the LXCs.
    proxmox.cloudInit.enable = false;
    proxmox.qemuConf = {
      cores = 2;
      memory = 2048;
    };
    virtualisation.diskSize = 20 * 1024;
  };
}
