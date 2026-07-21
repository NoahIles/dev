# NixOS Desktop

My NixOS config — niri (Wayland compositor) + noctalia (shell) on an AMD/NVIDIA desktop.

Dual-boots with CachyOS via Limine. The two OSes share a btrfs `@home` subvolume and a single ESP; NixOS lives in its own `@nixos` subvolume. NixOS installs **no bootloader** — CachyOS's Limine chainloads the NixOS kernel.

## What's in it

| Module | What it does |
|---|---|
| `configuration.nix` | Base system — networking, users, sudo, nix settings |
| `modules/boot.nix` | Kernel selection, zram (no bootloader — Limine handles that) |
| `modules/desktop.nix` | niri + greetd autologin, PipeWire, polkit, Nautilus |
| `modules/gaming.nix` | Steam, Gamescope, etc. |
| `modules/cli.nix` | CLI tools |
| `modules/fonts.nix` | Fonts (including Apple SF via flake input) |
| `modules/ssh.nix` | SSH config |
| `home.nix` | Home Manager — packages and the dotfiles it manages |
| `configs/` | App configs (niri, noctalia, fish, fuzzel, etc.) |
| `hardware-configuration.nix` | Machine-specific: filesystems, GPU, bluetooth |

## Trying this config

### 1. Generate your hardware config

From a NixOS installer or existing install:

```bash
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

Replace the checked-in `hardware-configuration.nix` with yours. You'll need to keep or adapt:

- The btrfs subvolume layout (`@nixos` for `/`, `@home` for `/home`) — or flatten to whatever you use
- The NVIDIA block if you have a different GPU (or remove it)
- The Logitech/bluetooth sections if you don't need them

### 2. Remove Limine-specific bits

If you're using a normal NixOS bootloader (systemd-boot, GRUB), replace `modules/boot.nix`:

```nix
{...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVars = true;
  zramSwap.enable = true;
}
```

You can ignore `limine-sync.sh` entirely — it only matters for the Limine chainload setup.

### 3. Build

```bash
cd desktop
sudo nixos-rebuild switch --flake .#desktop
```

Or use `rebuild.sh`, which also formats with `alejandra`, detects kernel changes, and commits:

```bash
./rebuild.sh                          # auto-commits as "rebuild: <timestamp>"
./rebuild.sh "commit subject"         # custom commit message
```

### 4. First login

The config autologins as `noah` via greetd → niri-session. On first boot, set a real password:

```bash
passwd
```

(The `initialPassword` in `configuration.nix` is just `noah` — it only applies when the user is first created.)

## Dual-boot notes

This setup assumes CachyOS (or another Linux) owns Limine on the ESP. `limine-sync.sh` copies the NixOS kernel to `/boot/nixos/`, signs it with `sbctl` for Secure Boot, and appends a `/+NixOS` entry to `/boot/limine.conf`. It runs automatically via `rebuild.sh` when the kernel version changes.

If you're not dual-booting, just use a normal bootloader per step 2 above and skip `limine-sync.sh`.
