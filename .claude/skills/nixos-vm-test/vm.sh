#!/usr/bin/env bash
# Boot and drive the .#vm config for testing. See SKILL.md.
#   vm.sh up [--reuse] [--window]   build, boot, wait for SSH
#   vm.sh ssh [cmd...]              run a command in the guest
#   vm.sh login                     type the password at the greeter
#   vm.sh shot <out.png>            screenshot the guest desktop to the host
#   vm.sh down                      clean shutdown (disk kept for --reuse)
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
flake=${VM_FLAKE:-$(cd "$here/../../../desktop" && pwd)} # the checkout this script lives in
dir=${VM_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/nixos-vm-test}
user=${VM_USER:-noah} # ponytail: other users need vm.nix support first
port=2223
mkdir -p "$dir"

die() { echo "vm.sh: $*" >&2; exit 1; }
running() { [ -f "$dir/pid" ] && kill -0 "$(cat "$dir/pid")" 2>/dev/null; }
mon() { printf '%s\n' "$@" | nc -U -N "$dir/mon.sock" >/dev/null; }
sshopts=(-p "$port" -o BatchMode=yes -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$user@localhost")
gssh() { ssh "${sshopts[@]}" "$@"; }
gbash() { gssh bash -s; } # script on stdin; the guest login shell is fish

cmd=${1:-}; shift || true
case "$cmd" in
up)
  reuse="" display="-display egl-headless"
  for a in "$@"; do
    case "$a" in
      --reuse) reuse=1 ;;
      --window) display="" ;; # keep vm.nix's gtk window
      *) die "unknown flag $a" ;;
    esac
  done
  running && die "a VM is already running; vm.sh down first"
  ss -ltn "sport = :$port" | grep -q LISTEN && die "port $port taken by a VM this script didn't start"
  if [ -z "$reuse" ]; then rm -f "$dir/vm.qcow2"; fi
  nix build "$flake#nixosConfigurations.vm.config.system.build.vm" -o "$dir/result"
  rm -f "$dir/mon.sock" "$dir/serial.log"
  start=$(date +%s)
  # Later -display wins over vm.nix's gtk one; a mkForce'd qemu.options would drop -kernel.
  # All fds redirected: an inherited stdout keeps a caller's pipe open forever.
  (cd "$dir" && NIX_DISK_IMAGE="$dir/vm.qcow2" QEMU_KERNEL_PARAMS=console=ttyS0 \
    QEMU_OPTS="$display -monitor unix:$dir/mon.sock,server,nowait -serial file:$dir/serial.log" \
    exec setsid ./result/bin/run-nixos-vm-vm) </dev/null >"$dir/qemu.log" 2>&1 &
  echo $! >"$dir/pid"
  # QEMU accepts the forwarded port before sshd listens, so a probe can hang.
  until timeout 10 ssh "${sshopts[@]}" true 2>/dev/null; do
    running || die "QEMU exited; see $dir/qemu.log and $dir/serial.log"
    [ $(($(date +%s) - start)) -gt 300 ] && die "no SSH after 300s; see $dir/serial.log"
    sleep 3
  done
  echo "up in $(($(date +%s) - start))s ($([ -n "$reuse" ] && echo reused || echo fresh) disk, logs in $dir)"
  ;;
ssh) gssh "$@" ;;
login)
  keys=()
  for ((i = 0; i < ${#user}; i++)); do keys+=("sendkey ${user:i:1}"); done # password = username
  mon "${keys[@]}" "sendkey ret"
  for _ in $(seq 60); do
    # noctalia's socket, not the compositor's: a bare compositor screenshots black.
    gbash <<<'test -S /run/user/$(id -u)/noctalia-wayland-0.sock' && { echo "session up"; exit 0; }
    sleep 1
  done
  die "no Wayland session 60s after login; greeter not ready, or wrong password?"
  ;;
shot)
  out=${1:?usage: vm.sh shot <out.png>}
  # Wayland socket of the logged-in session; empty means nobody's logged in.
  gbash <<<'export WAYLAND_DISPLAY=$(basename "$(ls /run/user/$(id -u)/wayland-? 2>/dev/null | head -1)")
        [ -n "$WAYLAND_DISPLAY" ] || { echo "no session: vm.sh login first" >&2; exit 1; }
        grim -' >"$out"
  echo "$out"
  ;;
down)
  running || { echo "not running"; exit 0; }
  mon system_powerdown
  for _ in $(seq 60); do running || break; sleep 1; done
  running && { mon quit; echo "forced quit after 60s"; }
  rm -f "$dir/pid"
  ;;
*) sed -n '2,7p' "$0"; exit 1 ;;
esac
