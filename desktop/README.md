# NixOS Desktop

My NixOS config — niri (Wayland compositor) + noctalia (shell) on an AMD/NVIDIA desktop.

Dual-boots with CachyOS via Limine. The two OSes share a btrfs `@home` subvolume and a single ESP; NixOS lives in its own `@nixos` subvolume. NixOS owns the Limine bootloader and includes CachyOS and Windows as extra entries.

## What's in it

| Module | What it does |
|---|---|
| `configuration.nix` | Base system — networking and Nix settings |
| `identity.nix` / `modules/identity.nix` | Host user, home directory, user creation, and rebuild sudo access |
| `modules/boot.nix` | Limine bootloader, kernel selection, CachyOS/Windows entries, zram |
| `modules/desktop.nix` | niri + greetd autologin, PipeWire, polkit, Nautilus |
| `modules/gaming.nix` | Steam, Gamescope, etc. |
| `modules/cli.nix` | CLI tools |
| `modules/fonts.nix` | Fonts (including Apple SF via flake input) |
| `modules/ssh.nix` | Optional SSH service and authorized keys |
| `home.nix` | Home Manager — packages and the dotfiles it manages |
| `configs/` | App configs (niri, noctalia, fish, fuzzel, etc.) |
| `hardware-configuration.nix` | Machine-specific: filesystems, GPU, bluetooth |

## Trying this config

For a full new-host deployment guide, see [`../docs/getting_started.md`](../docs/getting_started.md).

### 1. Generate your hardware config

From a NixOS installer or existing install:

```bash
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

Replace the checked-in `hardware-configuration.nix` with yours. You'll need to keep or adapt:

- The btrfs subvolume layout (`@nixos` for `/`, `@home` for `/home`) — or flatten to whatever you use
- The NVIDIA block if you have a different GPU (or remove it)
- The Logitech/bluetooth sections if you don't need them

### 2. Adapt Bootloader Settings

This host uses the native NixOS Limine module and writes the Limine config to the shared ESP. If you're using a different bootloader, replace the Limine block in `modules/boot.nix` with your bootloader settings:

```nix
{...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVars = true;
  zramSwap.enable = true;
}
```

### 3. Build

```bash
cd desktop
sudo nixos-rebuild switch --flake .#desktop
```

Or use `rebuild.sh`, which also formats with `alejandra`, shows the Nix diff, compares the build with `nvd`, switches, and commits with the `nvd` output in the commit body:

```bash
./rebuild.sh                          # auto-commits as "rebuild: <timestamp>"
./rebuild.sh "commit subject"         # custom commit message
```

### 4. First login

The config autologins as the user in `identity.nix` via greetd → niri-session.
On first boot, set a real password:

```bash
passwd
```

(The `initialPassword` in `modules/identity.nix` only applies when the user is first created.)

## Dual-boot notes

This setup assumes NixOS owns Limine on the ESP via `boot.loader.limine`. The generated config lives under `/boot/limine/limine.conf`; CachyOS and Windows are declared as extra entries in `modules/boot.nix`.

`boot.loader.timeout = 1` controls the Limine menu timeout. The native NixOS Limine generator also writes its own `default_entry` for the newest NixOS generation, so avoid adding another `default_entry` in `boot.loader.limine.extraConfig` unless you have verified how duplicate Limine keys are resolved.
