{
  config,
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [inputs.owly.nixosModules.default];
  # Seeded by nixos-generate-config 2026-07-13, hand-maintained since.
  # Deliberately NOT named hardware-configuration.nix: the generator
  # overwrites that filename unconditionally (--force only guards
  # configuration.nix). To refresh from a new machine, generate into a
  # scratch dir and merge by hand.
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
    # 615 (latest) hangs on resume from suspend. TLOU corruption was 590+, not 580.
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

  # bluetooth (Magic Keyboard) — pairing persists in /var/lib/bluetooth.
  hardware.bluetooth = {
    enable = true;
    package = pkgs-unstable.bluez;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  # Unplugging the Magic Keyboard's USB cable hands it to Bluetooth: pair
  # it if BlueZ forgot it, re-trust it every time (an untrusted keyboard
  # gets "Authentication attempt without agent -> Access denied" when it
  # reconnects on its own), then connect. A cabled keyboard keeps its radio
  # off, so there's no pairing over USB like a Mac does it.
  # Pairing a stranger needs the keyboard advertising: power it off/on.
  services.udev.extraRules = ''
    ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="5ac/29a/*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start magic-keyboard-bt.service"
  '';
  systemd.services.magic-keyboard-bt = {
    description = "Pair, trust and connect the Magic Keyboard over Bluetooth";
    after = ["bluetooth.service"];
    requires = ["bluetooth.service"];
    serviceConfig.Type = "oneshot";
    path = [config.hardware.bluetooth.package];
    script = ''
      mac=B0:BE:83:E7:DD:7E
      for _ in $(seq 10); do
        paired() { bluetoothctl info "$mac" | grep -q 'Paired: yes'; }
        paired || bluetoothctl --timeout 8 scan on >/dev/null || true
        # Trust BEFORE pairing: mid-pair the keyboard opens its HID channel,
        # and an untrusted device sends that to the shell's agent as a
        # "trust?" prompt; pairing fails unless someone clicks it.
        bluetoothctl trust "$mac" || continue
        if ! paired; then
          # Run our own agent as the default one for the pairing, and say
          # yes to its prompts; otherwise the confirmation goes to the
          # shell's agent (noctalia's "Trust and allow" popup) and times out.
          # --agent registers nothing in one-shot mode, hence the pipe.
          # BlueZ gives the default role back to noctalia when we quit.
          # Pairing took >15s on 2026-11-14, so allow 45.
          {
            echo default-agent
            echo "pair $mac"
            for _ in $(seq 45); do
              sleep 1
              paired && break
              echo yes
            done
            echo quit
          } | bluetoothctl --agent NoInputNoOutput >/dev/null || true
          paired || continue
        fi
        bluetoothctl --timeout 10 connect "$mac" && exit 0
        sleep 3
      done
      echo "gave up: keyboard not reachable (asleep, or bonded to another host?)" >&2
      exit 1
    '';
  };

  # AirDrop to/from iPhones via the MT7922 Wi-Fi card (unused: the box is on
  # Ethernet, so exclusive mode taking Wi-Fi down costs nothing). mt7921e
  # is "untested" in owly's drivers.toml, hence the opt-in. Firewall
  # (TCP 8771 on awdl0) is opened by the module. iPhone must be set to
  # "Everyone for 10 minutes".
  services.owly = {
    enable = true;
    settings.allow_untested = true;
  };
  # owly's packaged mt7921e entry wants an active monitor, which this
  # kernel's mt7921e doesn't offer ("card doesn't support an active
  # monitor"). Exclusive mode runs a hidden AP instead (card has AP mode).
  # The override replaces owly's whole entry for the driver.
  environment.etc."owly/drivers.toml".source = (pkgs.formats.toml {}).generate "drivers.toml" {
    drivers.mt7921e = {
      status = "untested";
      mode = "exclusive";
      channels = [6]; # owly's notes: 5 GHz injection never reached the air
    };
  };
}
