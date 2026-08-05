# Getting Started

This guide adapts the `desktop` flake to a new machine. It assumes you are
already booted into a NixOS installer or an existing NixOS system with the
target filesystems mounted correctly.

For what each module actually does, see
[`../desktop/README.md`](../desktop/README.md).

## 1. Put the checkout at `~/nixos`

The live-lane Home Manager dotfiles point at `~/nixos/desktop/configs` so
their edits can hot-reload and remain in the checkout. Clone the repository at
that location before the first switch.

The config lives on the **`nixos` branch** of `NoahIles/dev`; that repo's
default branch (`master`) is unrelated. If you just want to build it, clone
that one branch:

```bash
git clone --single-branch --branch nixos https://github.com/NoahIles/dev.git ~/nixos
cd ~/nixos/desktop
```

To fork it instead, note that `gh repo fork --default-branch-only` would give
you `master`. Fork, retarget the default branch, then clone the one branch:

```bash
gh repo fork NoahIles/dev --fork-name nixos --clone=false
gh repo edit "$(gh api user -q .login)/nixos" --default-branch nixos
git clone --single-branch --branch nixos "git@github.com:$(gh api user -q .login)/nixos.git" ~/nixos
cd ~/nixos/desktop
```

The fork still carries the other branches upstream has; delete them in the
fork if you want a clean history view.

## 2. Set the host identity

Edit `desktop/identity.nix` before building:

```nix
rec {
  username = "your-user";
  homeDirectory = "/home/${username}";
  fullName = "Your Name";
  email = "you@example.com";
  hostName = "nixos";
  sshKeys = ["ssh-ed25519 AAAA... you@example.com"];
}
```

These values configure the NixOS user, Home Manager user, greetd autologin,
sudo permission for `nixos-rebuild`, `networking.hostName`, the git author
name/email, and SSH authorized keys. Keep
the UID in `modules/identity.nix` aligned with any existing account when
sharing a home directory with another OS.

`initialPassword` is set to the username only for the first account creation.
Set a real password immediately after boot with `passwd`, or replace it before
deployment.

## 3. Remove machine-specific services you do not want

SSH is optional. To omit the checked-in keys and the OpenSSH service, remove
this line from the `sharedModules` list in `desktop/flake.nix`:

```nix
./modules/ssh.nix
```

Removing the import is sufficient; keeping the unused module file does not
affect the evaluated configuration. If you keep it, replace the authorized
keys and review the configured port and authentication settings.

Also review the modules included only by the bare-metal `desktop` target:

- `hardware-configuration.nix` for storage, GPU, Bluetooth, and peripherals.
- `modules/boot.nix` for the Limine and shared-ESP setup.
- `modules/gaming.nix` and `modules/udev-wootility.nix` for optional desktop
  hardware and workflow choices.

## 4. Generate the hardware configuration

Replace `desktop/hardware-configuration.nix` with one generated for the
target machine:

```bash
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

Then add back only the settings required by the target, such as its filesystem
layout, CPU microcode, graphics driver, and peripherals. Do not carry over the
checked-in disk UUIDs, btrfs subvolumes, NVIDIA settings, sensor module, or
Bluetooth device assumptions.

## 5. Choose a bootloader

`modules/boot.nix` is specific to this dual-boot system: NixOS owns Limine on
a shared ESP and adds CachyOS and Windows entries. Replace it with the target
bootloader configuration if that is not your layout, or remove it from the
bare-metal module list and add your own boot module.

## 6. Validate and deploy

From `~/nixos/desktop`, evaluate both configurations and build the target
before switching it:

```bash
nix flake check
sudo nixos-rebuild build --flake .#desktop
sudo nixos-rebuild switch --flake .#desktop
```

For normal changes on this machine, `./rebuild.sh` formats, builds, switches,
and commits. Do not use it until the host-specific changes above are complete.

## Gotchas

### Live dotfile symlinks require the checkout path

The `live` helper in `desktop/modules/home/dotfiles.nix` uses
`mkOutOfStoreSymlink` to symlink `~/.config/<app>` to the repo checkout so
hand-edits hot-reload without a rebuild. This requires a **string** containing
the real filesystem path -- not a Nix path expression.

In flake mode, any Nix path (e.g. `../../configs`) is copied into
`/nix/store` at eval time. `builtins.toString` on that path gives you the
store path, not the original location on disk. Flakes are pure by design --
there is no built-in way for a flake to discover where its own source lives.

This means `configsDir` uses the conventional checkout location:

```nix
configsDir = "${config.home.homeDirectory}/nixos/desktop/configs";
```

If the repo moves from `~/nixos`, update this string. Alternatives
(`--impure` + `builtins.getEnv`, passing the path via `specialArgs` from
`rebuild.sh`) exist but aren't worth the complexity unless the repo location
actually varies.

**Symptom if broken:** apps like fish spam `Read-only file system (os error
30)` because their config dir points into `/nix/store`.
