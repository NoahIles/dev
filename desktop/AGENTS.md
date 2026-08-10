# Repository Guidelines

## Project Structure & Module Organization

This repository is a NixOS flake for the `desktop` host plus a VM target. Top-level entry points are `flake.nix`, `configuration.nix`, `home.nix`, `modules/hardware.nix`, and `vm.nix`.

- `modules/*.nix`: system modules. Keep portable modules separate from hardware-locked choices.
- `modules/home/*.nix`: Home Manager modules for packages, apps, terminal setup, dotfiles, and audio.
- `configs/`: app configuration files managed by Home Manager, including niri, noctalia, fish, Zed, mpv, PipeWire, fuzzel, and swaylock.
- `limine-theme-cachyos/`: Limine theme assets and Nix wiring.
- `CONTEXT.md`: project vocabulary and architecture principles. Read it before moving module boundaries or dotfile ownership.

There is no conventional source/test split; validation is done by formatting and Nix builds.

## Build, Test, and Development Commands

- `nix flake check`: run flake-level checks when available.
- `sudo nixos-rebuild build --flake .#desktop`: build the desktop system without switching.
- `nixos-rebuild build-vm --flake .#vm`: build the VM configuration for safer validation.
- `./rebuild.sh`: format, show Nix diff, build, compare with `nvd`, switch, and amend an auto-generated rebuild commit whose body includes the `nvd` output.
- `./rebuild.sh "subject"`: same flow with a custom commit subject.

## Coding Style & Naming Conventions

Use Alejandra formatting for all Nix. Keep modules cohesive and named by responsibility, for example `modules/performance.nix` or `modules/home/terminal.nix`. Prefer clear attribute sets over clever abstraction. Use comments only for non-obvious hardware, boot, or shared-home constraints.

## Testing Guidelines

Before committing Nix changes, run `alejandra -q .` and at least `sudo nixos-rebuild build --flake .#desktop`. Use `nixos-rebuild build-vm --flake .#vm` for desktop startup, Home Manager import, or hardware-independent module changes. For hardware-specific edits, document what could not be validated locally.

## Commit & Pull Request Guidelines

Recent history uses short scoped subjects such as `gaming: add Proton tools`, `home: configure pointer cursor`, and generated `rebuild: <timestamp>` commits. Keep subjects concise and mention the affected area when useful.

When committing a successful rebuild manually, include the `nvd diff /run/current-system result` output in the commit body. Prefer `./rebuild.sh "subject"` or `just rebuild "subject"` so this is captured automatically.

PRs should include intent, validation commands, and manual checks such as login, niri reload, audio routing, or VM boot. Include screenshots only for visible UI/theme changes.

## Agent-Specific Instructions

Do not rewrite unrelated generated dotfiles or machine-specific settings. Respect the live-lane/stable-lane distinction in `CONTEXT.md`, and avoid moving hardware-locked configuration into portable modules.
