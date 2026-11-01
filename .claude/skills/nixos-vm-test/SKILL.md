---
name: nixos-vm-test
description: Boot this repo's `.#vm` config in QEMU and verify a change inside it. Use for first-boot and onboarding changes (seeded settings, default wallpaper, install script, minimal install), for proving a fix resolves an issue beyond "it evaluates", and when a change is too risky to switch onto NixIsland untested.
---

# NixOS VM test

`vm.sh` (next to this file) builds and boots the `vm` config from the checkout it
lives in, so in a worktree it tests that worktree's changes. `vm` is the desktop
config plus `desktop/vm.nix`; hardware-locked parts (nvidia, Limine, Secure Boot)
are forced off there.

```bash
S=.claude/skills/nixos-vm-test/vm.sh
$S up [--reuse] [--window]   # build, boot, wait for SSH; prints boot time
$S ssh 'cmd'                 # run in the guest as noah; fish syntax, so wrap
                             #   POSIX scripts: $S ssh bash -s <<'EOF' ... EOF
$S login                     # type the password (= username), wait for the session
$S shot out.png              # grim screenshot of the logged-in session
$S down                      # clean poweroff; disk kept
```

State lives in `~/.cache/nixos-vm-test` (disk, `serial.log`, `qemu.log`,
monitor socket `mon.sock`). One VM at a time on host port 2223.

## Pick the modes

- **Disk: fresh** (default) wipes the disk, so the boot is a first boot: home-manager
  activation, one-time seeds, `~/nixos` checkout. Use it for anything onboarding.
- **Disk: `--reuse`** keeps the disk. Use it for idempotency: run the step on a
  fresh boot, `down`, `up --reuse`, run it again, and diff the results. Also for an
  existing install picking up a config change.
- **Display: headless** (default) runs `-display egl-headless`; evidence comes from
  `ssh` and `shot`. **`--window`** opens vm.nix's gtk window for Noah to click
  around; leave it running for him instead of calling `down`.

## Steps

1. Write down what "verified" means for this change before booting: the files,
   units, or screen state that prove it. Each check must have an observable
   pass/fail.
2. `up` with the right modes. Failure to reach SSH: read `serial.log`.
3. Run every check over `ssh`. For seeded or first-boot state, check content, not
   just existence. For services: `systemctl --user --failed` and `journalctl -b`.
4. For anything visual: `login` (returns once noctalia is running), `shot`, then
   Read the PNG. A black shot means noctalia hadn't drawn yet: take it again. The session is whatever the greeter defaults to (umbriel today).
5. Idempotency changes: repeat 3–4 after `down` + `up --reuse`.
6. `down` (unless `--window`). Report each check as pass/fail with its evidence:
   command output or screenshot path.

## Gotchas

- QEMU `screendump` fails ("no surface") with virtio-vga-gl, headless or not, so
  screenshots come from `grim` inside the guest (installed by vm.nix).
- Never `lib.mkForce` `virtualisation.qemu.options`: it drops `-kernel/-initrd`
  and the VM silently never boots. Add flags through `QEMU_OPTS`, as vm.sh does.
- A second VM next to a running one needs a different port: `extendModules` on
  `nixosConfigurations.vm` with
  `virtualisation.vmVariant.virtualisation.forwardPorts = lib.mkForce [{from="host"; host.port=2224; guest.port=2222;}]`.
- What the real machine has but a fresh box lacks, so what can't pass in the VM:
  `docs/vm-undeclared-state.md`. Add to it when a test finds new undeclared state.
- Testing as a different user and hostname isn't supported yet: vm.nix hardcodes
  identity. `VM_USER` only changes who vm.sh logs in as.
