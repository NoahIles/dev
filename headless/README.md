# headless — NixOS-WSL CLI host

A self-contained flake like `desktop/`, minus everything graphical. Same CLI
packages (`desktop/modules/cli.nix`), same fish and starship config, and the
same Claude Code setup — `modules/home/claude.nix` is imported from `desktop/`
through a source-only `path:../desktop` input, so the two hosts can't drift.

Attribute `NixWsl`, hostname `NixWsl`, user `noah`.

## Build the tarball (on the desktop)

```bash
cd ~/nixos/headless
sudo nix run .#nixosConfigurations.NixWsl.config.system.build.tarballBuilder
```

That writes `nixos.wsl` in the current directory. Copy it somewhere Windows
can see it, for example `/mnt/c/Users/<you>/Downloads/`.

## Import it (in Windows)

```powershell
wsl --install --no-distribution   # only if WSL isn't set up yet
wsl --install --from-file nixos.wsl
wsl -d NixOS
```

Double-clicking `nixos.wsl` does the same thing on WSL 2.4.4 and newer.

## First run inside WSL

The Claude links dangle until the repos are there, so clone both first:

```bash
git clone <nixos remote> ~/nixos
git clone ubu-1:/srv/git/llm-wiki.git ~/Documents/llm-wiki
curl -fsSL https://claude.ai/install.sh | bash   # the binary isn't from nix
sudo nixos-rebuild switch --flake ~/nixos/headless#NixWsl
```

Then log in to Claude Code. Don't copy `.credentials.json` over.

## After changing a shared file

`cli.nix`, `identity.nix` and `modules/home/claude.nix` come from the pinned
`desktop` input, so this flake keeps building the old copy until you re-lock:

```bash
cd ~/nixos/headless && nix flake lock --update-input desktop
```
